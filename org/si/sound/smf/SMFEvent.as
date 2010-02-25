//----------------------------------------------------------------------------------------------------
// SMF event
//  modified by keim.
//  This soruce code is distributed under BSD-style license (see org.si.license.txt).
//
// Original code
//  url; http://wonderfl.net/code/0aad6e9c1c5f5a983c6fce1516ea501f7ea7dfaa
//  Copyright (c) 2010 nemu90kWw All rights reserved.
//  The original code is distributed under MIT license.
//  (see http://www.opensource.org/licenses/mit-license.php).
//----------------------------------------------------------------------------------------------------


package org.si.sound.smf {
    import flash.utils.ByteArray;
    
    
    /** SMF event */
    public class SMFEvent
    {
    // constant
    //--------------------------------------------------------------------------------
        static public const NOTE_OFF:int = 0x80;
        static public const NOTE_ON:int = 0x90;
        static public const KEY_PRESSURE:int = 0xa0;
        static public const CONTROL_CHANGE:int = 0xb0;
        static public const PROGRAM_CHANGE:int = 0xc0;
        static public const CHANNEL_PRESSURE:int = 0xd0;
        static public const PITCH_BEND:int = 0xe0;
        static public const SYSTEM_EXCLUSIVE:int = 0xf0;
        static public const SYSTEM_EXCLUSIVE_SHORT:int = 0xf7;
        static public const META:int = 0xff;
        
        static public const META_SEQNUM:int = 0xff00;
        static public const META_TEXT:int = 0xff01;
        static public const META_AUTHOR:int = 0xff02;
        static public const META_TITLE:int = 0xff03;
        static public const META_INSTRUMENT:int = 0xff04;
        static public const META_LYLICS:int = 0xff05;
        static public const META_MARKER:int = 0xff06;
        static public const META_CUE:int = 0xff07;
        static public const META_PROGRAM_NAME:int = 0xff08;
        static public const META_DEVICE_NAME:int = 0xff09;
        static public const META_CHANNEL:int = 0xff20;
        static public const META_PORT:int = 0xff21;
        static public const META_TRACK_END:int = 0xff2f;
        static public const META_TEMPO:int = 0xff51;
        static public const META_SMPTE_OFFSET:int = 0xff54;
        static public const META_TIME_SIGNATURE:int = 0xff58;
        static public const META_KEY_SIGNATURE:int = 0xff59;
        static public const META_SEQUENCER_SPEC:int = 0xff7f;
        
        static private var _noteText:Vector.<String> = Vector.<String>(["c ","c+","d ","d+","e ","f ","f+","g ","g+","a ","a+","b "]);
        
        
        
    // variables
    //--------------------------------------------------------------------------------
        public var type:int = 0;
        public var value:int = 0;
        public var byteArray:ByteArray = null;
        
        public var deltaTime:uint = 0;
        public var time:uint = 0;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** channel */
        public function get channel() : int { return (type >= SYSTEM_EXCLUSIVE) ? 0 : (type & 0x0f); }
        
        /** note */
        public function get note() : int { return value >> 16; }
        
        /** velocity */
        public function get velocity() : int { return value & 0x7f; }
        
        /** text data */
        public function get text() : String { return (byteArray) ? byteArray.readUTF() : ""; }
        public function set text(str:String) : void {
            if (!byteArray) byteArray = new ByteArray();
            byteArray.writeUTF(str);
        }
        
        
        /** toString */
        public function toString() : String
        {
            switch(type) {
            case NOTE_ON:
                return (velocity > 0) ? _noteText[note % 12] + ":" + velocity : "";
            case CONTROL_CHANGE:
                return "CC:" + (value>>16) + " " + (value&0xffff) + " ";
            case PROGRAM_CHANGE:
                return "PC:" + value + " ";
            case SYSTEM_EXCLUSIVE:
            case SYSTEM_EXCLUSIVE_SHORT:
                var text:String = "SX:";
                if (byteArray) {
                    byteArray.position = 0;
                    while (byteArray.bytesAvailable>0) {
                        text += byteArray.readUnsignedByte().toString(16)+" ";
                    }
                }
                return text;
            }

            return "";
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function SMFEvent(type:int, value:int, deltaTime:int, time:int) 
        {
            this.type = type;
            this.value = value;
            this.deltaTime = deltaTime;
            this.time = time;
        }
    }
}

