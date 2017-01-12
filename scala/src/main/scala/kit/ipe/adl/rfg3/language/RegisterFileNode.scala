package kit.ipe.adl.rfg3.language

import org.odfi.indesign.core.harvest.HarvestedResource

/**
 * @author zm4632
 */
trait RegisterFileNode extends HarvestedResource {
  
  /**
        The ID of the target host whose registerfile is to be interacted with
    */
    var id : Short
    
    def getId = id.toString
  
}