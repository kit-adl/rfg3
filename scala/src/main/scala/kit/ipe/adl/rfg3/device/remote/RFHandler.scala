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
package kit.ipe.adl.rfg3.device.remote

import com.idyria.osi.wsb.core.message.soap.SOAPMessagesHandler
import kit.ipe.adl.rfg3.device.Device
import uni.hd.cag.osys.rfg.rf.device.remote.ReadResponse
import uni.hd.cag.osys.rfg.rf.device.remote.WriteResponse
import uni.hd.cag.osys.rfg.rf.device.remote.WriteRequest
import uni.hd.cag.osys.rfg.rf.device.remote.ReadRequest




object RFHandler extends SOAPMessagesHandler {
  
  /**
   * Handle reads
   */
  on[ReadRequest] {
    (message,request) => 
      
      // Read
      val readValue = Device.readRegister(request.nodeID.toShort, request.address,1) match {
        case Some(v) => v
        case None => throw new RuntimeException(s"Could not read value from nodeID ${request.nodeID} @0x${request.address.data.toInt.toHexString}")
      }
      
      
      // Send Response
      val response = ReadResponse()
      response.value = readValue(0)
      
      response
  }
  
  on[WriteRequest] {
    (message,request) => 
      
      // Write
      Device.writeRegister(request.nodeID.toShort, request.address,Array(request.value.data))
      
      // response
      WriteResponse()
  }
  
}

