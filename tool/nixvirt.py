import sys, uuid, lxml, libvirt

# Switch off annoying libvirt stderr messages
# https://stackoverflow.com/a/45543887
def libvirt_callback(userdata, err):
    pass
libvirt.registerErrorHandler(f=libvirt_callback, ctx=None)

def getConnection(uri):
    return libvirt.open(uri)

class ObjectConnection:
    def __init__(self,type,conn,verbose):
        self.type = type
        self.conn = conn
        self.verbose = verbose

    def vreport(self,objid,msg):
        if self.verbose:
            print (self.type + " " + str(uuid.UUID(bytes=objid)) + ": " + msg, file=sys.stderr)

    def getAll(self):
        return map(lambda lvobj: VObject(self,lvobj), self.getAllLV())

    def fromLVObject(self,lvobj):
        return VObject(self,lvobj) if lvobj else None

    def fromUUID(self,uuid):
        return self.fromLVObject(self.lookupByUUID(uuid))

    def fromUUIDOrNone(self,uuid):
        try:
            return self.fromUUID(uuid)
        except libvirt.libvirtError:
            return None

    def fromName(self,name):
        return self.fromLVObject(self.lookupByName(name))

    def fromXML(self,defn):
        return self.fromLVObject(self.defineXML(defn))

    def undefine(self,lvobj):
        lvobj.undefine()

    def define(self,specDefXML):
        specUUID = uuid.UUID(specDefXML.find("uuid").text).bytes
        found = self.fromUUIDOrNone(specUUID)
        if found is not None:
            foundActive = found.isActive()
            foundDef = found.XMLDesc()
            foundDefXML = lxml.etree.fromstring(foundDef)
            foundName = foundDefXML.find("name").text
            specName = specDefXML.find("name").text
            if foundName != specName:
                found.undefine()
            self.vreport(specUUID,"redefine")
            subject = self.fromXML(specDef)
            subjectDef = subject.XMLDesc()
            defchanged = foundDef != subjectDef
            self.vreport(specUUID,"changed" if defchanged else "unchanged")
            if defchanged:
                found.deactivate()
                deactivated = foundActive
            else:
                deactivated = False
            return (subject,deactivated)
        else:
            self.vreport(specUUID,"define new")
            subject = self.fromXML(specDef)
            return (subject,False)

class DomainConnection(ObjectConnection):
    def __init__(self,conn,verbose):
        ObjectConnection.__init__(self,"domain",conn,verbose)
    def getAllLV(self):
        return self.conn.listAllDomains()
    def lookupByUUID(self,uuid):
        return self.conn.lookupByUUID(uuid)
    def lookupByName(self,name):
        return self.conn.lookupByName(name)
    def defineXML(self,defn):
        return self.conn.defineXML(defn)
    def XMLDesc(self,lvobj):
        return lvobj.XMLDesc(flags=2) # VIR_DOMAIN_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainXMLFlags
    def undefine(self,lvobj):
        lvobj.undefineFlags(flags=72) # VIR_DOMAIN_UNDEFINE_KEEP_NVRAM, VIR_DOMAIN_UNDEFINE_KEEP_TPM, https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainUndefineFlagsValues

class NetworkConnection(ObjectConnection):
    def __init__(self,conn,verbose):
        ObjectConnection.__init__(self,"network",conn,verbose)
    def getAllLV(self):
        return self.conn.listAllNetworks()
    def lookupByUUID(self,uuid):
        return self.conn.networkLookupByUUID(uuid)
    def lookupByName(self,name):
        return self.conn.networkLookupByName(name)
    def defineXML(self,defn):
        return self.conn.networkDefineXML(defn)
    def XMLDesc(self,lvobj):
        return lvobj.XMLDesc(flags=1) # VIR_NETWORK_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkXMLFlags

# https://libvirt.org/html/libvirt-libvirt-storage.html
class PoolConnection(ObjectConnection):
    def __init__(self,conn,verbose):
        ObjectConnection.__init__(self,"pool",conn,verbose)
    def getAllLV(self):
        return self.conn.listAllStoragePools()
    def lookupByUUID(self,uuid):
        return self.conn.storagePoolLookupByUUID(uuid)
    def lookupByName(self,name):
        return self.conn.storagePoolLookupByName(name)
    def defineXML(self,defn):
        return self.conn.storagePoolDefineXML(defn) # https://libvirt.org/formatstorage.html
    def XMLDesc(self,lvobj):
        return lvobj.XMLDesc(flags=1) # VIR_STORAGE_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-storage.html#virStorageXMLFlags

objectTypes = ['domain','network','pool']

def getObjectConnection(conn,type,verbose):
    match type:
        case "domain":
            return DomainConnection(conn,verbose)
        case "network":
            return NetworkConnection(conn,verbose)
        case "pool":
            return PoolConnection(conn,verbose)

def getObjectConnectionFromURI(uri,type,verbose):
    return getObjectConnection(getConnection(uri),type,verbose)

class VObject:
    def __init__(self,oc,lvobj):
        self.oc = oc
        self.lvobj = lvobj
        self.uuid = lvobj.UUID()

    def vreport(self,msg):
        self.oc.vreport(self.uuid,msg)

    def isActive(self):
        return self.lvobj.isActive()

    def activate(self):
        if not self.isActive():
            self.vreport("activate")
            self.lvobj.create()

    def deactivate(self):
        if self.isActive():
            self.vreport("deactivate")
            self.lvobj.destroy()

    def setAutostart(self,a):
        self.vreport("set autostart true" if a else "set autostart false")
        self.lvobj.setAutostart(a)

    def XMLDesc(self):
        return self.oc.XMLDesc(self.lvobj)

    def undefine(self):
        isPersistent = self.lvobj.isPersistent()
        self.deactivate()
        if isPersistent:
            self.vreport("undefine")
            self.oc.undefine(self.lvobj)
