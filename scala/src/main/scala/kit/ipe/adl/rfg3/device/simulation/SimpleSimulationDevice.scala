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


/**
 * @author fzahn
 *
 */
class SimpleSimulationDevice extends Device {

  
  
  def open = {

  }

  def close = {

  }

  // Node -> RegisterFile Map
  //-----------------
  var nodesMap = scala.collection.mutable.Map[Short, scala.collection.mutable.Map[Long, Long]]()

  private def getNodeMap(nodeId: Short): scala.collection.mutable.Map[Long, Long] = {

    nodesMap.get(nodeId) match {
      case Some(map) => map
      case None =>
        var nodeMap = scala.collection.mutable.Map[Long, Long]()
        nodesMap = nodesMap + (nodeId -> nodeMap)
        nodeMap

    }

  }

  def readRegister(nodeId: Short, address: Long,size:Int): Option[Array[Long]] = {

 //   println("Read from  " + nodeId)

    // Get node Map and read
    //-----------
    this.getNodeMap(nodeId).get(address) match {
      case Some(v) => Some(Array(v))
      case None => Some(Array(0))
    }

  }

  def writeRegister(nodeId: Short, address: Long, value: Array[Long]) = {

  //  println("Writing to " + nodeId)
    
    this.getNodeMap(nodeId) += (address -> value(0))
  }

}

/**
 * Companion object to open/close the native interface
 */
object SimpleSimulationDevice {

  def apply() = new SimpleSimulationDevice
}
