package kit.ipe.adl.rfg3


import kit.ipe.adl.rfg3.device.DeviceSource
import kit.ipe.adl.rfg3.device.DeviceHarvester
import org.odfi.indesign.core.module.IndesignModule
import org.odfi.indesign.core.harvest.Harvest

object RFGModule extends IndesignModule {
  
  this.onLoad {
    Harvest.registerAutoHarvesterObject(classOf[DeviceSource], DeviceHarvester)
  }
  
  
}