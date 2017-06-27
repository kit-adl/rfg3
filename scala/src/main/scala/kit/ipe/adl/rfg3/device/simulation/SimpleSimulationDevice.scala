/*

RFG Register File Generator
Copyright (C) 2014  University of Heidelberg - Computer Architecture Group

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/
package kit.ipe.adl.rfg3.device.simulation

import kit.ipe.adl.rfg3.device.Device
import kit.ipe.adl.rfg3.model.Register
import kit.ipe.adl.rfg3.language.RegisterFileHost


/**
 *
 *
 */
class SimpleSimulationDevice extends Device {

  isPhysical = false
  
  /**
   * Number of values saved for a specific address
   */
  var defaultSaveFrameDepth = 512
  
  def open = {

  }

  def close = {

  }
  
  

  // Node -> RegisterFile Map
  //-----------------
  var nodesMap = scala.collection.mutable.Map[Short, scala.collection.mutable.Map[Long, Array[Long]]]()

  private def getNodeMap(nodeId: Short): scala.collection.mutable.Map[Long,  Array[Long]] = {

    nodesMap.get(nodeId) match {
      case Some(map) => map
      case None =>
        var nodeMap = scala.collection.mutable.Map[Long,  Array[Long]]()
        nodesMap = nodesMap + (nodeId -> nodeMap)
        nodeMap

    }

  }
  
  // Get values
  //---------------
  def getValuesOfRegister(target:RegisterFileHost , r:Register) = {
    
   r.findAttributeLong("::odfi::rfg::address.absolute") match {
     case Some(address) => 
       
       this.getNodeMap(target.id).get(address) match {
         case Some(values) => Some(values) 
         case None => None
       }
       
     case None => 
       logWarn("Simulated values for register: "+r.name+" not available, address ::odfi::rfg::address.absolute not defined on attributes")
       None
   }
    
  }

  // Read Write
  //--------------
  def readRegister(nodeId: Short, address: Long,size:Int): Option[Array[Long]] = {

 //   println("Read from  " + nodeId)

    // Get node Map and read
    //-----------
    this.getNodeMap(nodeId).get(address) match {
      case Some(v) => Some(Array(v.last))
      case None => Some(Array(0))
    }

  }

  def writeRegister(nodeId: Short, address: Long, value: Array[Long]) = {

  //  println("Writing to " + nodeId)
    //-- Get Map for node and update content
    this.getNodeMap(nodeId).get(address) match {
      
      // Update values
      case Some(values) => 
        
        this.getNodeMap(nodeId).update(address, (values ++ value).takeRight(defaultSaveFrameDepth)) 
        
      case None => 
        
        this.getNodeMap(nodeId).update(address,value.takeRight(defaultSaveFrameDepth))
    }

  }

}

/**
 * Companion object to open/close the native interface
 */
object SimpleSimulationDevice {

  def apply() = new SimpleSimulationDevice
}
