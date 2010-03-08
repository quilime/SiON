//----------------------------------------------------------------------------------------------------
// Standard MIDI File class
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
    
    
    /** Standard MIDI File class */
    public class SMFData
    {
    // variables
    //--------------------------------------------------------------------------------
        public var format:int;
        public var numTracks:int;
        public var resolution:int;
        public var bpm:int = 0;
        public var text:String = "";
        public var title:String = null;
        public var author:String = null;
        public var signature_n:int = 0;
        public var signature_d:int = 0;
        public var tracks:Vector.<SMFTrack> = new Vector.<SMFTrack>();
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** Is avaiblable ? */
        public function isAvailable() : Boolean { return (numTracks > 0); }
        
        
        /** to string. */
        public function toString():String
        {
            var text:String = "";
            text += "format : SMF" + format + "\n";
            text += "numTracks : " + numTracks + "\n";
            text += "resolution : " + (resolution>>2) + "\n";
            text += "title : " + title + "\n";
            text += "author : " + author + "\n";
            text += "signature : " + signature_n + "/" + signature_d + "\n";
            text += "BPM : " + bpm + "\n";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function SMFData()
        {
            
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : SMFData
        {
            format = 0;
            numTracks = 0;
            resolution = 0;
            bpm = 0;
            text = null;
            title = null;
            author = null;
            signature_n = 0;
            signature_d = 0;
            tracks.length = 0;
            
            return this;
        }
        
        
        /** Load SMF data from byteArray. */
        public function loadBytes(bytes:ByteArray) : SMFData
        {
            bytes.position = 0;
            clear();
            
            var len:uint, temp:ByteArray = new ByteArray();
            while (bytes.bytesAvailable > 0) {
                var type:String = bytes.readMultiByte(4, "us-ascii");
                switch(type) {
                case "MThd":
                    bytes.position += 4;
                    format = bytes.readUnsignedShort();
                    numTracks = bytes.readUnsignedShort();
                    resolution = bytes.readUnsignedShort() << 2;
                    break;
                case "MTrk":
                    len = bytes.readUnsignedInt();
                    bytes.readBytes(temp, 0, len);
                    tracks.push(new SMFTrack(this, tracks.length, temp));
                    break;
                default:
                    len = bytes.readUnsignedInt();
                    bytes.position += len;
                    break;
                }
            }
            
            if (text == null) text = "";
            if (title == null) title = "";
            if (author == null) author = "";
            
            return this;
        }
    }
}


