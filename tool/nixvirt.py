import sys, uuid, libvirt

# Switch off annoying libvirt stderr messages
# https://stackoverflow.com/a/45543887
def libvirt_callback(userdata, err):
    pass
libvirt.registerErrorHandler(f=libvirt_callback, ctx=None)

class ObjectConnection:
    def __init__(self,uri,verbose):
        self.conn = libvirt.open(uri)
        self.verbose = verbose

    def vreport(self,objid,msg):
        if self.verbose:
            print (self.type + " " + str(uuid.UUID(bytes=objid)) + ": " + msg, file=sys.stderr)

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

class DomainConnection(ObjectConnection):
    def __init__(self,uri,verbose):
        ObjectConnection.__init__(self,uri,verbose)
        self.type = "domain"
    def lookupByUUID(self,uuid):
        return self.conn.lookupByUUID(uuid)
    def lookupByName(self,name):
        return self.conn.lookupByName(name)
    def defineXML(self,defn):
        return self.conn.defineXML(defn)
    def XMLDesc(self,lvobj):
        return lvobj.XMLDesc(flags=2) # VIR_DOMAIN_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainXMLFlags

class NetworkConnection(ObjectConnection):
    def __init__(self,uri,verbose):
        ObjectConnection.__init__(self,uri,verbose)
        self.type = "network"
    def lookupByUUID(self,uuid):
        return self.conn.networkLookupByUUID(uuid)
    def lookupByName(self,name):
        return self.conn.networkLookupByName(name)
    def defineXML(self,defn):
        return self.conn.networkDefineXML(defn)
    def XMLDesc(self,lvobj):
        return lvobj.XMLDesc(flags=1) # VIR_NETWORK_XML_INACTIVE, https://libvirt.org/html/libvirt-libvirt-network.html#virNetworkXMLFlags

def getObjectConnection(uri,type,verbose):
    match type:
        case "domain":
            return DomainConnection(uri,verbose)
        case "network":
            return NetworkConnection(uri,verbose)

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
        lvobj.setAutostart(a)

    def XMLDesc(self):
        return oc.XMLDesc(lvobj)

    def undefine(self):
        self.vreport("undefine")
        lvobj.undefine()
