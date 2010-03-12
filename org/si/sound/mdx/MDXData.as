//----------------------------------------------------------------------------------------------------
// MDX data class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import org.si.sion.SiONData;
    import org.si.sion.SiONVoice;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMOperatorParam;
    import org.si.sion.sequencer.base.MMLEvent;
    import flash.utils.ByteArray;
    
    
    /** MDX data class */
    public class MDXData
    {
    // variables
    //--------------------------------------------------------------------------------
        public var isPCM8:Boolean;
        public var bpm:Number = 0;
        public var title:String = null;
        public var pdxFileName:String = null;
        public var voices:Vector.<SiONVoice>  = new Vector.<SiONVoice>(256, true);
        public var tracks:Vector.<MDXTrack>  = new Vector.<MDXTrack>(16, true);
        public var globalEvents:Vector.<MDXEvent> = new Vector.<MDXEvent>();
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** Is avaiblable ? */
        public function isAvailable() : Boolean { return false; }
        
        
        /** to string. */
        public function toString():String
        {
            var text:String = "";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function MDXData()
        {
            
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : MDXData
        {
            var i:int;
            isPCM8 = false;
            bpm = 0;
            title = null;
            pdxFileName = null;
            globalEvents.length = 0;
            for (i=0; i<16; i++) tracks[i] = null;
            for (i=0; i<256; i++) voices[i] = null;
            return this;
        }
        
        
        /** convert to SiONData 
         *  @param data SiONData to convert to, pass null to create new SiONData inside.
         *  @return converted SiONData
         */
        public function convertToSiONData(data:SiONData=null, pdxData:PDXData=null) : SiONData
        {
            var i:int, imax:int, prevClock:uint, currentClock:uint;
            
            if (data == null) data = new SiONData();
            data.clear();
            
            data.bpm = bpm;
            data.globalSequence.initialize();
            imax = globalEvents.length;
            currentClock = prevClock = 0;
            for (i=0; i<imax; i++) {
                switch(globalEvents[i].type) {
                case MDXEvent.TIMERB:
                    currentClock = globalEvents[i].clock;
                    if (prevClock < currentClock) data.globalSequence.appendNewEvent(MMLEvent.WAIT, (currentClock-prevClock)*10);
                    data.globalSequence.appendNewEvent(MMLEvent.TEMPO, 4883/(256-globalEvents[i].data));
                    prevClock = currentClock;
                    break;
                }
            }

            imax = (isPCM8) ? 16 : 9;
            for (i=0; i<imax; i++) {
                tracks[i]._constructMMLSequence(data.appendNewSequence());
            }
            
            imax = voices.length;
            for (i=0; i<imax; i++) {
                data.voices[i] = voices[i]
            }
            
            if (pdxData) {
                imax = 96;
                for (i=0; i<imax; i++) data.setPCMData(i, pdxData.pcmData[i]);
            }
            
            return data;
        }
        
        
        /** Load MDX data from byteArray. */
        public function loadBytes(bytes:ByteArray) : MDXData
        {
            var titleLength:int, pdxLength:int, dataPointer:int, voiceOffset:int, voiceLength:int,
                voiceCount:int, i:int, mmlOffsets:Array = new Array(16);
            
            // initialize
            clear();
            bytes.endian = "bigEndian";
            bytes.position = 0;
            
            // title
            while (true) { if (bytes.readByte() == 0x0d && bytes.readByte() == 0x0a && bytes.readByte() == 0x1a) break; }
            titleLength = bytes.position - 3;
            bytes.position = 0;
            title = bytes.readMultiByte(titleLength, "us-ascii"); //shift_jis
            bytes.position = titleLength + 3;
            
            // pdx file
            while (true) { if (bytes.readByte() == 0) break; }
            pdxLength = bytes.position - titleLength - 4;
            pdxFileName = bytes.readMultiByte(pdxLength, "us-ascii");
            bytes.position = titleLength + pdxLength + 4;
            
            // data offsets
            dataPointer = bytes.position;
            voiceOffset = bytes.readUnsignedShort();  // tone data
            for (i=0; i<16; i++) mmlOffsets[i] = dataPointer + bytes.readUnsignedShort();
            // check pcm8
            bytes.position = mmlOffsets[0];
            isPCM8 = (bytes.readUnsignedByte() == 0xe8);
            
            // load voices
            bytes.position = dataPointer + voiceOffset;
            voiceLength = (mmlOffsets[0] > voiceOffset) ? (mmlOffsets[0] - voiceOffset) : (bytes.length - dataPointer - voiceOffset);  // ...?
            _loadVoices(bytes, voiceLength);
            
            // load tracks
            _loadTracks(bytes, mmlOffsets);
            
            return this;
        }
        
        
        // Load voice data from byteArray.
        private function _loadVoices(bytes:ByteArray, voiceLength:int) : void
        {
            var i:int, opi:int, v:int, voice:SiONVoice, voiceNumber:int, fbalg:int, mask:int, 
                opp:SiOPMOperatorParam, reg:Array = [], opia:Array = [3,1,2,0], dt2Table:Array = [0, 384, 500, 608];
            
            for (i=0; i<voiceLength; i+=27) {
                voiceNumber = bytes.readUnsignedByte();
                fbalg = bytes.readUnsignedByte();
                mask  = bytes.readUnsignedByte();
                for (opi=0; opi<6; opi++) { reg[opi] = bytes.readUnsignedInt(); }
                
                if (voices[voiceNumber] == null) voices[voiceNumber] = new SiONVoice();
                voice = voices[voiceNumber];
                voice.initialize();
                voice.chipType = SiONVoice.CHIPTYPE_OPM;
                voice.channelParam.opeCount = 4;
                
                voice.channelParam.fb  = (fbalg >> 3) & 7;
                voice.channelParam.alg = (fbalg) & 7;
                
                for (opi=0; opi<4; opi++) {
                    opp = voice.channelParam.operatorParam[opia[opi]];
                    opp.mute = (((mask >> opi) & 1) == 0);
                    v = (reg[0] >> (opi<<3)) & 255;
                    opp.dt1  = (v >> 4) & 7;
                    opp.fmul = (v & 7) << 7;
                    opp.tl   = (reg[1] >> (opi<<3)) & 127;
                    v = (reg[2] >> (opi<<3)) & 255;
                    opp.ksr = (v >> 6) & 3;
                    opp.ar  = (v & 31) << 1;
                    v = (reg[3] >> (opi<<3)) & 255;
                    opp.ams = ((v >> 7) & 1) << 1;
                    opp.dr  = (v & 31) << 1;
                    v = (reg[4] >> (opi<<3)) & 255;
                    opp.detune = dt2Table[(v >> 6) & 3];
                    opp.sr     = (v & 31) << 1;
                    v = (reg[5] >> (opi<<3)) & 255;
                    opp.sl = (v >> 4) & 15;
                    opp.rr = (v & 15) << 2;
                }
            }
        }
        
        
        // load mml tracks
        private function _loadTracks(bytes:ByteArray, mmlOffsets:Array) : void
        {
            var i:int, imax:int = (isPCM8) ? 16 : 9;
            // load tracks
            for (i=0; i<imax; i++) {
                bytes.position = mmlOffsets[i];
                tracks[i] = new MDXTrack(this, i);
                tracks[i].loadBytes(bytes);
            }
            
            // sort all global events
            globalEvents = globalEvents.sort(function(a:MDXEvent, b:MDXEvent) : Number { return (a.clock - b.clock); });
            
            // load bpm
            bpm = 87.19642857142857; // 4883/(256-200)
            imax = globalEvents.length;
            for (i=0; i<imax; i++) {
                if (globalEvents[i].clock > 0) break;
                if (globalEvents[i].type == MDXEvent.TIMERB) {
                    bpm = 4883/(256-globalEvents[i].data);//4370.285//4883
                    break;
                }
            }
        }
    }
}


