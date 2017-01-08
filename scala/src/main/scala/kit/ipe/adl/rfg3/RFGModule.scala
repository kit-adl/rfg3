package kit.ipe.adl.rfg3

import edu.kit.ipe.adl.indesign.core.module.IndesignModule
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import kit.ipe.adl.rfg3.device.DeviceSource
import kit.ipe.adl.rfg3.device.DeviceHarvester

object RFGModule extends IndesignModule {
  
  this.onLoad {
    Harvest.registerAutoHarvesterObject(classOf[DeviceSource], DeviceHarvester)
  }
  
  
}