package kit.ipe.adl.rfg3.model

import com.idyria.osi.tea.bit.TeaBitUtil
import com.idyria.osi.ooxoo.core.buffers.datatypes.LongBuffer

/**
 * This Buffer represents a verilog value, which is defined as:
 *
 * SIZE'TYPEVALUE
 *
 * TYPE = h,b,d etc..
 */
class VerilogLongValue extends LongBuffer {

  var originalStringValue = "0"

  /**
   * Parse Verilog value
   */
  override def dataFromString(str: String): Long = {

    this.originalStringValue = str
    var resValue: Long = 0
    //println("Parsing: "+str)

    var expr = """(?i)([0-9]+)'(b|h|d)([A-Fa-f0-9]+)?""".r
    expr.findFirstMatchIn(str) match {

      //-> HEx Match, parse value
      case Some(m) if (m.group(2) == "h") =>

        resValue = java.lang.Long.decode(s"0x${m.group(3)}")

      //-> B match
      case Some(m) if (m.group(2) == "b") =>

        // Every character is a bit
        var offset = 0
        m.group(3).reverse.foreach {
          c =>
            resValue = TeaBitUtil.setBits(resValue, offset, offset, java.lang.Long.parseLong(s"$c"))
            offset += 1
        }

      //-> Decimal match, let normal long parse value
      case Some(m) if (m.group(2) == "d") =>

  
        resValue = m.group(3) match {
          case null => 0
          case v => super.dataFromString(v)
        }

      //-> No match, let normal long parse value
      case None if (str.matches("[0-9]+")) =>

        // Only Do if 
        resValue = super.dataFromString(str)

      //-> No match but keep value 0 if a Define is referenced
      case None if (str.matches(".*`.*")) =>
        resValue = 0
      case _ =>
        throw new IllegalArgumentException(s"""Verilog Value matched format for input: $str , but match case was not handled""")

    }

    this.data = resValue
    this.data
  }

  /**
   * Return the last parsed representation
   */
  override def toString: String = this.originalStringValue

}

object VerilogLongValue {

  def apply(init: Long) = {
    var obj = new VerilogLongValue()
    obj.data = init
    obj
  }

  implicit def convertStringToVerilogLongValue(str: String): VerilogLongValue = {

    var value = new VerilogLongValue
    value.data = value.dataFromString(str)
    value

  }
}