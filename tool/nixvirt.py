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

    def fromUUID(self,uuid):
        return self._fromLVObject(self._lookupByUUID(uuid))

    def fromUUIDOrNone(self,uuid):
        try:
            return self.fromUUID(uuid)
        except libvirt.libvirtError:
            return None

    def fromName(self,name):
        return self._fromLVObject(self._lookupByName(name))

    def _fromXML(self,defn):
        return self._fromLVObject(self._defineXML(defn))

    def _undefine(self,lvobj):
        lvobj.undefine()

    def _getDependents(self,uuid):
        return []

    def _tempDeactivateDependents(self,uuid):
        dependents = self._getDependents(uuid)
        for dependent in dependents:
            dependent._deactivate(temp = True)

    def _recordTempDeactivated(self,uuid):
        self.session._recordTempDeactivated(self,uuid)

    def _wasTempDeactivated(self,uuid):
        return self.session._wasTempDeactivated(self,uuid)

    def fromDefinition(self,specDef):
        specDefXML = lxml.etree.fromstring(specDef)
        specUUID = uuid.UUID(specDefXML.find("uuid").text).bytes
        found = self.fromUUIDOrNone(specUUID)
        if found is not None:
            foundDef = found.descriptionXML()
            foundDefXML = lxml.etree.fromstring(foundDef)
            foundName = foundDefXML.find("name").text
            specName = specDefXML.find("name").text
            if foundName != specName:
                found.undefine()
            self.vreport(specUUID,"redefine")
            subject = self._fromXML(specDef)
            subjectDef = subject.descriptionXML()
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
    def _lookupByUUID(self,uuid):
        return self.conn.lookupByUUID(uuid)
    def _lookupByName(self,name):
        return self.conn.lookupByName(name)
    def _defineXML(self,defn):
        return self.conn.defineXML(defn)
    def _descriptionXML(self,lvobj):
        return lvobj.XMLDesc(flags=2) # VIR_DOMAIN_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainXMLFlags
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
    def _lookupByUUID(self,uuid):
        return self.conn.networkLookupByUUID(uuid)
    def _lookupByName(self,name):
        return self.conn.networkLookupByName(name)
    def _defineXML(self,defn):
        return self.conn.networkDefineXML(defn)
    def _descriptionXML(self,lvobj):
        return lvobj.XMLDesc(flags=1) # VIR_NETWORK_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkXMLFlags
    def _getDependents(self,uuid):
        domains = DomainConnection(self.session).getAll()
        for domain in domains:
            # https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainInterfaceAddressesSource
            # VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_AGENT
            ia = domain._lvobj.interfaceAddresses(1)
            vreport(uuid,"interface: " + str(ia))
        return []

# https://libvirt.org/html/libvirt-libvirt-storage.html
class PoolConnection(ObjectConnection):
    def __init__(self,session):
        ObjectConnection.__init__(self,"pool",session)
    def _getAllLV(self):
        return self.conn.listAllStoragePools()
    def _lookupByUUID(self,uuid):
        return self.conn.storagePoolLookupByUUID(uuid)
    def _lookupByName(self,name):
        return self.conn.storagePoolLookupByName(name)
    def _defineXML(self,defn):
        return self.conn.storagePoolDefineXML(defn) # https://libvirt.org/formatstorage.html
    def _descriptionXML(self,lvobj):
        return lvobj.XMLDesc(flags=1) # VIR_STORAGE_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageXMLFlags

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
        self.uuid = lvobj.UUID()

    def vreport(self,msg):
        self.oc.vreport(self.uuid,msg)

    def isActive(self):
        return self._lvobj.isActive()

    def _activate(self):
        if not self.isActive():
            self.vreport("activate")
            self._lvobj.create()

    def _deactivate(self,temp = False):
        if self.isActive():
            self.oc._tempDeactivateDependents(self.uuid)
            if temp:
                self.oc._recordTempDeactivated(self.uuid)
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
                if self.oc._wasTempDeactivated(self.uuid):
                    self._activate()

    def setAutostart(self,a):
        self.vreport("set autostart true" if a else "set autostart false")
        self._lvobj.setAutostart(a)

    def descriptionXML(self):
        return self.oc._descriptionXML(self._lvobj)

    def undefine(self):
        isPersistent = self._lvobj.isPersistent()
        self._deactivate()
        if isPersistent:
            self.vreport("undefine")
            self.oc._undefine(self._lvobj)
