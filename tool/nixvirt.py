import sys, uuid, lxml, libvirt

# Switch off annoying libvirt stderr messages
# https://stackoverflow.com/a/45543887
def libvirt_callback(userdata, err):
    pass
libvirt.registerErrorHandler(f=libvirt_callback, ctx=None)

class Session:
    def __init__(self,uri,verbose):
        self.conn = libvirt.open(uri)
        self.verbose = verbose
        self.tempDeactivated = set()

    def vreport(self,msg):
        if self.verbose:
            print (msg, file=sys.stderr)

    # These are all objects that were temporarily deactivated, that is, for reasons other than user request
    def _recordTempDeactivated(self,oc,uuid):
        self.tempDeactivated.add((oc.type,uuid))

    def _wasTempDeactivated(self,oc,uuid):
        return (oc.type,uuid) in self.tempDeactivated

class ObjectConnection:
    def __init__(self,type,session):
        self.type = type
        self.session = session
        self.conn = session.conn

    def vreport(self,objid,msg):
        self.session.vreport(self.type + " " + str(uuid.UUID(bytes=objid)) + ": " + msg)

    def getAll(self):
        return map(lambda lvobj: VObject(self,lvobj), self._getAllLV())

    def _fromLVObject(self,lvobj):
        return VObject(self,lvobj) if lvobj else None

    def fromUUID(self,objid):
        return self._fromLVObject(self._lookupByUUID(objid))

    def fromUUIDOrNone(self,objid):
        try:
            return self.fromUUID(objid)
        except libvirt.libvirtError:
            return None

    def fromName(self,name):
        return self._fromLVObject(self._lookupByName(name))

    def _fromXML(self,defn):
        return self._fromLVObject(self._defineXML(defn))

    def _undefine(self,lvobj):
        lvobj.undefine()

    def _getDependents(self,obj):
        return []

    def _tempDeactivateDependents(self,obj):
        dependents = self._getDependents(obj)
        for dependent in dependents:
            dependent._deactivate(temp = True)

    def _recordTempDeactivated(self,objid):
        self.session._recordTempDeactivated(self,objid)

    def _wasTempDeactivated(self,objid):
        return self.session._wasTempDeactivated(self,objid)

    def fromDefinition(self,specDef):
        specDefXML = lxml.etree.fromstring(specDef)
        specUUID = uuid.UUID(specDefXML.find("uuid").text).bytes
        found = self.fromUUIDOrNone(specUUID)
        if found is not None:
            foundDef = found.descriptionXMLText()
            foundDefXML = lxml.etree.fromstring(foundDef)
            foundName = foundDefXML.find("name").text
            specName = specDefXML.find("name").text
            if foundName != specName:
                found.undefine()
            self.vreport(specUUID,"redefine")
            subject = self._fromXML(specDef)
            subjectDef = subject.descriptionXMLText()
            defchanged = foundDef != subjectDef
            self.vreport(specUUID,"changed" if defchanged else "unchanged")
            if defchanged:
                found._deactivate(temp = True)
            return subject
        else:
            self.vreport(specUUID,"define new")
            return self._fromXML(specDef)

    def fromDefinitionFile(self,path):
        with open(path,"r") as f:
            specDef = f.read()
        return self.fromDefinition(specDef)

class DomainConnection(ObjectConnection):
    def __init__(self,session):
        ObjectConnection.__init__(self,"domain",session)
    def _getAllLV(self):
        return self.conn.listAllDomains()
    def _lookupByUUID(self,objid):
        return self.conn.lookupByUUID(objid)
    def _lookupByName(self,name):
        return self.conn.lookupByName(name)
    def _defineXML(self,defn):
        return self.conn.defineXML(defn)
    def _descriptionXMLText(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainXMLFlags
        # VIR_DOMAIN_XML_INACTIVE
        return lvobj.XMLDesc(flags=2)
    def _undefine(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainUndefineFlagsValues
        # VIR_DOMAIN_UNDEFINE_MANAGED_SAVE
        # VIR_DOMAIN_UNDEFINE_KEEP_NVRAM
        # VIR_DOMAIN_UNDEFINE_KEEP_TPM
        lvobj.undefineFlags(flags=73)

class NetworkConnection(ObjectConnection):
    def __init__(self,session):
        ObjectConnection.__init__(self,"network",session)
    def _getAllLV(self):
        return self.conn.listAllNetworks()
    def _lookupByUUID(self,objid):
        return self.conn.networkLookupByUUID(objid)
    def _lookupByName(self,name):
        return self.conn.networkLookupByName(name)
    def _defineXML(self,defn):
        # https://libvirt.org/formatnetwork.html
        return self.conn.networkDefineXML(defn)
    def _descriptionXMLText(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkXMLFlags
        # VIR_NETWORK_XML_INACTIVE
        return lvobj.XMLDesc(flags=1)
    def _getDependents(self,obj):
        names = obj.descriptionXMLETree().xpath("/network/bridge/@name")
        domains = DomainConnection(self.session).getAll()
        for domain in domains:
            intfs = domain.descriptionXMLETree().xpath("/domain/devices/interface/source/@bridge")
            for intf in intfs:
                self.vreport(obj.objid,"interface: " + str(intf))
                for name in names:
                    self.vreport(obj.objid,"bridge: " + str(name))
        return []

# https://libvirt.org/html/libvirt-libvirt-storage.html
class PoolConnection(ObjectConnection):
    def __init__(self,session):
        ObjectConnection.__init__(self,"pool",session)
    def _getAllLV(self):
        return self.conn.listAllStoragePools()
    def _lookupByUUID(self,objid):
        return self.conn.storagePoolLookupByUUID(objid)
    def _lookupByName(self,name):
        return self.conn.storagePoolLookupByName(name)
    def _defineXML(self,defn):
        # https://libvirt.org/formatstorage.html
        return self.conn.storagePoolDefineXML(defn)
    def _descriptionXMLText(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageXMLFlags
        # VIR_STORAGE_XML_INACTIVE
        return lvobj.XMLDesc(flags=1)

objectTypes = ['domain','network','pool']

def getObjectConnection(session,type):
    match type:
        case "domain":
            return DomainConnection(session)
        case "network":
            return NetworkConnection(session)
        case "pool":
            return PoolConnection(session)

class VObject:
    def __init__(self,oc,lvobj):
        self.oc = oc
        self._lvobj = lvobj
        self.objid = lvobj.UUID()

    def vreport(self,msg):
        self.oc.vreport(self.objid,msg)

    def isActive(self):
        return self._lvobj.isActive()

    def _activate(self):
        if not self.isActive():
            self.vreport("activate")
            self._lvobj.create()

    def _deactivate(self,temp = False):
        if self.isActive():
            self.oc._tempDeactivateDependents(self)
            if temp:
                self.oc._recordTempDeactivated(self.objid)
            self.vreport("deactivate (temporary)" if temp else "deactivate")
            self._lvobj.destroy()

    def setActive(self,s):
        match s:
            case True:
                self._activate()
            case False:
                self._deactivate()
            case null:
                # reactivate objects that were temporatily deactivated
                if self.oc._wasTempDeactivated(self.objid):
                    self._activate()

    def setAutostart(self,a):
        self.vreport("set autostart true" if a else "set autostart false")
        self._lvobj.setAutostart(a)

    def descriptionXMLText(self):
        return self.oc._descriptionXMLText(self._lvobj)

    def descriptionXMLETree(self):
        return lxml.etree.fromstring(self.descriptionXMLText())

    def undefine(self):
        isPersistent = self._lvobj.isPersistent()
        self._deactivate()
        if isPersistent:
            self.vreport("undefine")
            self.oc._undefine(self._lvobj)
