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
package kit.ipe.adl.rfg3.device

import java.lang.ref.WeakReference
import org.odfi.indesign.core.harvest.HarvestedResource
import org.odfi.indesign.core.harvest.Harvester
import kit.ipe.adl.rfg3.language.RegisterFileHost

/**
  *
  * Common trait for a Device to which we can read/write registers to
  *
  * @author rleys
  *
  */
trait Device extends HarvestedResource {

  var isPhysical = true

  def getId = getClass.getCanonicalName

  /**
    * Should throw an exception if the Device could not be opened
    */
  def open

  /**
    * Frees resources
    */
  def close

  /**
    * Should Return a Long value for the register @ provided address
    *
    */
  def readRegister(nodeId: Short, address: Long, size: Int): Option[Array[Long]]

  /**
    * Writes the register value @ provided address
    */
  def writeRegister(nodeId: Short, address: Long, value: Array[Long])

}

trait DeviceSource extends Harvester

object DeviceHarvester extends Harvester {

  onDeliverFor[Device] {
    case d =>
      gather(d)
      true
  }

}

/**
  * The Device Singleton is the Read/Write interface for registers
  *
  * It delivers read/writes to the underlying Device implementation.
  * Thus there is only one active Device interface at any time,  but this is the whished behavior
  *
  *
  */
object Device extends Device {

  override def getId = "TopDevice"

  // var targetDevice: Option[Device] = None

  // var availableDevices = List[Device]()

  // Device Management
  //--------------

  /**
    * Add new avaible devices and clean old references as well
    */
  def addAvailableDevice(d: Device) = {
    // this.availableDevices = this.availableDevices.filter(p => p.get != null) :+ d
    //this.availableDevices = this.availableDevices :+ d
    DeviceHarvester.gatherDirect(d)
    d
  }

  def getDeviceOption(nodeId: Int) = {
    try {
      Some(this.getDevice(nodeId))
    } catch {
      case e: DeviceError => None
    }
  }

  def getDevice(nodeId: Int) = {

    //println("Looking for device id: "+nodeId)
    // Look into Device Harvester
    // If a device is a host and with same ID, use it
    DeviceHarvester.getResourcesOfType[RegisterFileHost].find { h => h.id == nodeId } match {
      case Some(d) if (d.hasDerivedResourceOfType[Device]) =>
        //println(s"Device id $nodeId found as DeviceHost")
        d.getDerivedResources[Device].head
      case other =>



        DeviceHarvester.getResourcesOfType[Device].sortBy(_.isPhysical).headOption match {
          case Some(d) => d
          case None =>
            throw new DeviceError("Cannot find a usable Physical RFG Device: No target device set, and no available devices")
        }

    }

  }

  def open = {
    //this.getDevice.open
  }

  def close = {

    // this.getDevice.close

  }

  def readRegister(nodeId: Short, address: Long, size: Int): Option[Array[Long]] = {

    val d = this.getDevice(nodeId)
    val res = d.readRegister(nodeId, address, size)

    //-- Also call read on non physical devices, to allow catching for debug
    DeviceHarvester.getResourcesOfType[Device].filterNot(_ == d).foreach {
      d =>
        keepErrorsOn(this) {
          d.readRegister(nodeId, address, size)
        }

    }
    res

  }

  def writeRegister(nodeId: Short, address: Long, value: Array[Long]) = {

    val d = this.getDevice(nodeId)
    d.writeRegister(nodeId, address, value)

    //-- Also call read on non physical devices, to allow catching for debug
    DeviceHarvester.getResourcesOfType[Device].filterNot(_ == d).foreach {
      d =>
        keepErrorsOn(this) {
          d.writeRegister(nodeId, address, value)
        }

    }

  }

}

class DeviceError(str: String) extends RuntimeException(str)