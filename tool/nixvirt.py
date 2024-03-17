import sys, uuid, hashlib, lxml, xmldiff.main, xmldiff.formatting, libvirt

# Switch off annoying libvirt stderr messages
# https://stackoverflow.com/a/45543887
def libvirt_callback(userdata, err):
    pass
libvirt.registerErrorHandler(f=libvirt_callback, ctx=None)

def eTreeToXML(etree):
    return lxml.etree.tostring(etree).decode("utf-8")

def xmlToETree(xml):
    return lxml.etree.fromstring(xml)

class Session:
    def __init__(self,uri,verbose):
        self.conn = libvirt.open(uri)
        self.verbose = verbose

    def vreport(self,msg):
        if self.verbose:
            print (msg, file=sys.stderr)

class ObjectConnection:
    def __init__(self,type,session):
        self.type = type
        self.session = session
        self.conn = session.conn

    def vreport(self,objid,msg):
        self.session.vreport(self.type + " " + str(uuid.UUID(bytes=objid)) + ": " + msg)

    def getFile(self,path):
        self.session.vreport(self.type + ": reading " + path)
        with open(path,"r") as f:
            return f.read()

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

    def _deactivateDependents(self,obj):
        dependents = self._getDependents(obj)
        for dependent in dependents:
            dependent._deactivate()

    def _fixDefinitionETree(self,objid,specDefETree):
        return None

    def _assignMacAddress(self,objid,index):
        hash = hashlib.sha256()
        hash.update(objid)
        hash.update(index.to_bytes(4, "big"))
        bb = hash.digest()[0:3].hex(":")
        addr = "52:54:00:" + bb
        self.vreport(objid,"assigning MAC address " + addr)
        return addr

    def _defineExtra(self,lvobj,extra):
        pass

    def _relevantDefETree(self,specDefXML,defETree):
        return defETree

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
    def _descriptionXML(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainXMLFlags
        # VIR_DOMAIN_XML_INACTIVE
        return lvobj.XMLDesc(flags=2)
    def _undefine(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainUndefineFlagsValues
        # VIR_DOMAIN_UNDEFINE_MANAGED_SAVE
        # VIR_DOMAIN_UNDEFINE_KEEP_NVRAM
        # VIR_DOMAIN_UNDEFINE_KEEP_TPM
        lvobj.undefineFlags(flags=73)
    def _fixDefinitionETree(self,objid,specDefETree):
        interfaces = specDefETree.xpath("/domain/devices/interface")
        index = 0
        for interface in interfaces:
            addresses = interface.xpath("/interface/mac/@address")
            if len(addresses) == 0:
                addr = self._assignMacAddress(objid,index)
                mac = lxml.etree.Element("mac")
                mac.attrib["address"] = addr
                interface.append(mac)
            index += 1
            return specDefETree
        else:
            return None

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
    def _descriptionXML(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkXMLFlags
        # VIR_NETWORK_XML_INACTIVE
        return lvobj.XMLDesc(flags=1)
    def _getDependents(self,obj):
        networknames = [name.text for name in obj.descriptionETree().xpath("/network/name")]
        bridgenames = [str(name) for name in obj.descriptionETree().xpath("/network/bridge/@name")]
        domains = DomainConnection(self.session).getAll()
        deps = []
        for domain in domains:
            domainbridgenames = domain.descriptionETree().xpath("/domain/devices/interface[@type='bridge']/source/@bridge")
            for name in domainbridgenames:
                if str(name) in bridgenames:
                    deps.append(domain)
                    break
            domainnetworknames = domain.descriptionETree().xpath("/domain/devices/interface[@type='network']/source/@network")
            for name in domainnetworknames:
                if str(name) in networknames:
                    deps.append(domain)
                    break
        return deps
    def _fixDefinitionETree(self,objid,specDefETree):
        addresses = specDefETree.xpath("/network/mac/@address")
        if len(addresses) == 0:
            addr = self._assignMacAddress(objid,0)
            mac = lxml.etree.Element("mac")
            mac.attrib["address"] = addr
            specDefETree.append(mac)
            return specDefETree
        else:
            return None

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
    def _descriptionXML(self,lvobj):
        # https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageXMLFlags
        # VIR_STORAGE_XML_INACTIVE
        return lvobj.XMLDesc(flags=1)
    def _defineExtra(self,pool,extra):
        volumes = extra.get("volumes")
        if volumes is not None:
            for volume in volumes:
                path = volume.get("definition")
                if path is not None:
                    volDefXML = self.getFile(path)
                    volDefETree = xmlToETree(volDefXML)
                    volName = volDefETree.find("name").text
                    pool._activate()
                    volLVObj = pool._lvobj.storageVolLookupByName(volName)
                    if volLVObj is not None:
                        pool.vreport("found volume " + volName)
                    else:
                        pool.vreport("creating volume " + volName)
                        volLVObj = pool._lvobj.storageVolCreateXML(volDefXML)
                    volLVObj.info()
    def _relevantDefETree(self,specDefXML,defETree):
        specDefETree = xmlToETree(specDefXML)

        def relevance(p):
            if len(specDefETree.xpath(p)) == 0:
                for node in defETree.xpath(p):
                    node.getparent().remove(node)

        relevance("/pool/capacity")
        relevance("/pool/allocation")
        relevance("/pool/available")
        relevance("/pool/target/permissions")
        return defETree

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

    def _deactivate(self):
        if self.isActive():
            self.oc._deactivateDependents(self)
            self.vreport("deactivate")
            self._lvobj.destroy()

    def setActive(self,s):
        if s:
            self._activate()
        else:
            self._deactivate()

    def setAutostart(self,a):
        self.vreport("set autostart true" if a else "set autostart false")
        self._lvobj.setAutostart(a)

    def descriptionXML(self):
        return self.oc._descriptionXML(self._lvobj)

    def descriptionETree(self):
        return xmlToETree(self.descriptionXML())

    def undefine(self):
        isPersistent = self._lvobj.isPersistent()
        self._deactivate()
        if isPersistent:
            self.vreport("undefine")
            self.oc._undefine(self._lvobj)

    def defineExtra(self,extra):
        self.oc._defineExtra(self,extra)

# what we want for an object
class ObjectSpec:

    def __init__(self,oc,specUUID = None,specName = None,specDefXML = None,active = None,extra = None):
        if specUUID is not None:
            self.subject = oc.fromUUIDOrNone(specUUID)
        elif specName is not None:
            self.subject = oc.fromName(specName)
            specUUID = self.subject.uuid
        else:
            self.subject = None
        if active is None:
            if self.subject is None:
                active = False
            else:
                active = self.subject.isActive()
        self.oc = oc
        self.specDefXML = specDefXML
        self.specName = specName
        self.specUUID = specUUID
        self.active = active
        self.extra = extra

    def vreport(self,msg):
        self.oc.vreport(self.specUUID,msg)

    def fromUUID(oc,specUUID,active):
        return ObjectSpec(oc,specUUID = specUUID,active = active)

    def fromName(oc,specName,active):
        return ObjectSpec(oc,specName = specName,active = active)

    def fromDefinition(oc,specDefXML,active,extra = None):
        specDefETree = xmlToETree(specDefXML)
        specUUID = uuid.UUID(specDefETree.find("uuid").text).bytes
        specName = specDefETree.find("name").text
        fixedDefETree = oc._fixDefinitionETree(specUUID,specDefETree)
        if fixedDefETree is not None:
            specDefXML = eTreeToXML(fixedDefETree)
        return ObjectSpec(oc,specUUID = specUUID,specName = specName,specDefXML = specDefXML,active = active, extra = extra)

    def fromDefinitionFile(oc,path,active,extra = None):
        specDefXML = oc.getFile(path)
        return ObjectSpec.fromDefinition(oc,specDefXML,active, extra = extra)

    def define(self):
        if self.specDefXML is not None:
            if self.subject is not None:
                oldDefETree = self.subject.descriptionETree()
                foundName = oldDefETree.find("name").text
                if foundName != self.specName:
                    self.subject.undefine()
                oldRelDefETree = self.oc._relevantDefETree(self.specDefXML,oldDefETree)
                self.vreport("redefine")
                newvobject = self.oc._fromXML(self.specDefXML)
                newRelDefETree = self.oc._relevantDefETree(self.specDefXML,newvobject.descriptionETree())
                diff = xmldiff.main.diff_trees(oldRelDefETree,newRelDefETree)
                if len(diff) > 0:
                    difftext = xmldiff.formatting.DiffFormatter().render(diff)
                    self.vreport("changed:\n" + difftext)
                    self.subject._deactivate()
                else:
                    self.vreport("unchanged")
                self.subject = newvobject
            else:
                self.vreport("define new")
                self.subject = self.oc._fromXML(self.specDefXML)

    def defineExtra(self):
        if self.subject is not None:
            self.subject.defineExtra(self.extra)

    def setActive(self):
        self.subject.setActive(self.active)
