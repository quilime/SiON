//----------------------------------------------------------------------------------------------------
// Track of MDX data
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.utils.ByteArray;
    import org.si.sion.SiONDriver;
    import org.si.sion.sequencer.SiMMLSequencer;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.sequencer.base.MMLEvent;
    
    
    /** Track of MDX data */
    public class MDXTrack
    {
    // variables
    //--------------------------------------------------------------------------------
        /** sequence */
        public var sequence:Vector.<MDXEvent> = new Vector.<MDXEvent>();
        /** Return pointer of segno */
        public var segnoPointer:MDXEvent;
        /** TIMER B value */
        public var timerB:int;
        /** channel number */
        public var channelNumber:int;
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** to string. */
        public function toString():String
        {
            var text:String = "";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function MDXTrack(channelNumber:int)
        {
            this.channelNumber = channelNumber;
            sequence = new Vector.<MDXEvent>();
            segnoPointer = null;
            timerB = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : MDXTrack
        {
            sequence.length = 0;
            segnoPointer = null;
            timerB = 0;
            return this;
        }
        
        
        /** Load track from byteArray. */
        public function loadBytes(bytes:ByteArray) : MDXTrack
        {
            clear();
            
            var code:int, v:int, clock:uint, pos:int, mem:Array=[], exitLoop:Boolean = false;
            clock = 0;
            
            while (!exitLoop) {
                pos = bytes.position;
                code = bytes.readUnsignedByte();
                if (code<0x80) { // rest
                    newEvent(MDXEvent.REST, 0, 0, code+1);
                    clock += code+1;
                } else
                if (code<0xe0) { // note
                    v = bytes.readUnsignedByte() + 1;
                    newEvent(MDXEvent.NOTE, code - 0x80, 0, v);
                    clock += v;
                } else {
                    switch(code) {
                    //----- 2 operands
                    case MDXEvent.REGISTER:
                    case MDXEvent.REPEAT_BEGIN:
                    case MDXEvent.FADEOUT:
                        newEvent(code, bytes.readUnsignedByte(), bytes.readUnsignedByte());
                        break;
                    //----- 1 operand
                    case MDXEvent.VOICE:
                    case MDXEvent.PAN:
                    case MDXEvent.VOLUME:
                    case MDXEvent.GATE:
                    case MDXEvent.KEY_ON_DELAY:
                    case MDXEvent.SYNC_SEND:
                    case MDXEvent.FREQUENCY:
                    case MDXEvent.LFO_DELAY:
                        newEvent(code, bytes.readUnsignedByte());
                        break;
                    //----- no operands
                    case MDXEvent.VOLUME_DEC:
                    case MDXEvent.VOLUME_INC:
                    case MDXEvent.SLUR:
                    case MDXEvent.SYNC_WAIT:
                    case MDXEvent.SET_PCM8:
                        newEvent(code);
                        break;
                    //----- 1 WORD operand
                    case MDXEvent.REPEAT_END:
                    case MDXEvent.REPEAT_BREAK:
                        newEvent(code, bytes.readUnsignedShort());
                        break;
                    case MDXEvent.DETUNE:
                    case MDXEvent.PORTAMENT:
                        newEvent(code, bytes.readShort()); //...?
                        break;
                    //----- others
                    case MDXEvent.TEMPO:
                        v = bytes.readUnsignedByte();
                        newEvent(code, v);
                        if (timerB == 0) timerB = v;
                        break;
                    case MDXEvent.PITCH_LFO:
                    case MDXEvent.VOLUME_LFO:
                        v = (bytes.readUnsignedByte() << 16) | bytes.readUnsignedShort();
                        newEvent(code, v, bytes.readUnsignedShort());
                        break;
                    case MDXEvent.OPM_LFO:
                        v = bytes.readUnsignedByte();
                        if (v == 0x80 || v == 0x81) newEvent(code, v<<24);
                        else {
                            v = (v<<16) | (bytes.readUnsignedByte()<<8) | bytes.readUnsignedByte();
                            newEvent(code, v, bytes.readUnsignedShort());
                        }
                        break;
                    case MDXEvent.DATA_END: // ...?
                        v = bytes.readUnsignedShort();
                        newEvent(code, bytes.readUnsignedShort());
                        if (v!=0) segnoPointer = mem[v];
                        exitLoop = true;
                        break;
                    default:
                        newEvent(MDXEvent.DATA_END);
                        exitLoop = true;
                        break;
                    }
                }
            }
            
            
            function newEvent(type:int, value:int=0, value2:int=0, deltaClock:int=0) : void {
                var inst:MDXEvent = new MDXEvent(type, value, value2, clock, deltaClock);
                sequence.push(inst);
                mem[pos] = inst;
            }
            
            return this;
        }
        
        
        /** @private [internal] construct MMLSequence */
        internal function _constructMMLSequence(simml:MMLSequence, tempo:Number) : void
        {
            if (SiONDriver.mutex == null) return;
            
            var i:int, v:int, imax:int, e:MDXEvent, me:MMLEvent, sequencer:SiMMLSequencer = SiONDriver.mutex.sequencer,  
                panTable:Array = [4,0,8,4], freqTable:Array = [18,23,30,35,42], 
                repeatStac:Array = [], lastNote:MMLEvent, lfoDelay:int=0,
                eventIDFadeOut:int = sequencer.getEventID("@fadeout"),
                eventIDPan:int     = sequencer.getEventID("p"),
                eventIDPShift:int  = sequencer.getEventID("k"),
                eventIDLFO:int     = sequencer.getEventID("@lfo"),
                eventIDAMod:int    = sequencer.getEventID("ma"),
                eventIDPMod:int    = sequencer.getEventID("mp"),
                eventIDIndex:int   = sequencer.getEventID("i");
            
                
            simml.initialize();
            simml.appendNewEvent(MMLEvent.MOD_TYPE, 6); // use FM voice
            
            imax = sequence.length;
            for (i=0; i<imax; i++) {
                e = sequence[i];
                if (segnoPointer === e) simml.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
                     if (e.type < 0x80) simml.appendNewEvent(MMLEvent.REST, 0, e.deltaClock*10);
                else if (e.type < 0xe0) lastNote = simml.appendNewEvent(MMLEvent.NOTE, e.value+12, e.deltaClock*10);
                else {
                    switch(e.type) {
                    case MDXEvent.REGISTER:
                        simml.appendNewEvent(MMLEvent.REGISTER, (e.value << 8) | e.value2);
                        break;
                    case MDXEvent.REPEAT_BEGIN:
                        repeatStac.unshift(simml.appendNewEvent(MMLEvent.REPEAT_BEGIN, e.value));
                        break;
                    case MDXEvent.FADEOUT:
                        simml.appendNewEvent(eventIDFadeOut, e.value2);
                        break;
                    case MDXEvent.TEMPO:
                        simml.appendNewEvent(MMLEvent.TEMPO, e.value);
                        break;
                    case MDXEvent.VOICE:
                        simml.appendNewEvent(MMLEvent.MOD_PARAM, e.value);
                        break;
                    case MDXEvent.PAN:
                        if (e.value == 0) simml.appendNewEvent(MMLEvent.VOLUME, 0);
                        else {
                            simml.appendNewEvent(MMLEvent.VOLUME, 16);
                            simml.appendNewEvent(eventIDPan, panTable[e.value]);
                        }
                        break;
                    case MDXEvent.VOLUME:
                        if (e.value < 16) simml.appendNewEvent(MMLEvent.FINE_VOLUME, e.value<<4);
                        else simml.appendNewEvent(MMLEvent.FINE_VOLUME, e.value & 127);
                        break;
                    case MDXEvent.GATE:
                        if (e.value < 9) {
                            simml.appendNewEvent(MMLEvent.QUANT_RATIO, e.value);
                            simml.appendNewEvent(MMLEvent.QUANT_COUNT, 0);
                        } else {
                            simml.appendNewEvent(MMLEvent.QUANT_RATIO, 8);
                            simml.appendNewEvent(MMLEvent.QUANT_COUNT, (256-e.value)*10);
                        }
                        break;
                    case MDXEvent.KEY_ON_DELAY:
                        simml.appendNewEvent(MMLEvent.KEY_ON_DELAY, e.value*10);
                        break;
                    case MDXEvent.VOLUME_DEC:
                        simml.appendNewEvent(MMLEvent.VOLUME_SHIFT, -1);
                        break;
                    case MDXEvent.VOLUME_INC:
                        simml.appendNewEvent(MMLEvent.VOLUME_SHIFT, 1);
                        break;
                    case MDXEvent.SLUR:
                        if (lastNote) {
                            simml.appendNewEvent(MMLEvent.SLUR_WEAK, 0, lastNote.length);
                            lastNote.length = 0;
                        }
                        break;
                    case MDXEvent.REPEAT_BREAK:
                        me = simml.appendNewEvent(MMLEvent.REPEAT_BREAK, 0);
                        me.jump = repeatStac[0];
                        break;
                    case MDXEvent.REPEAT_END:
                        me = simml.appendNewEvent(MMLEvent.REPEAT_END, 0);
                        me.jump = repeatStac.shift();
                        me.jump.jump = me;
                        break;
                    case MDXEvent.DETUNE:
                        simml.appendNewEvent(eventIDPShift, e.value);
                        break;
                    case MDXEvent.PORTAMENT:
                        if (lastNote) {
                            v = lastNote.data + (e.value * lastNote.length + 81920)/163840;
                            if (v<0) v=0;
                            else if (v>127) v=127;
                            simml.appendNewEvent(MMLEvent.PITCHBEND, 0, lastNote.length);
                            lastNote.length = 0;
                            simml.appendNewEvent(MMLEvent.NOTE, v, 0);
                        }
                        break;
                    case MDXEvent.LFO_DELAY:
                        lfoDelay = e.value*75/tempo;
                        break;
                    case MDXEvent.PITCH_LFO:
                        v = e.value>>16;
                        simml.appendNewEvent(eventIDLFO, (e.value&0xffff)*75/tempo * ((v&3)?2:1));
                        simml.appendNewEvent(MMLEvent.PARAMETER, v&3);
                        if (lfoDelay) {
                            simml.appendNewEvent(eventIDPMod, e.value2>>((v&4)?0:8));
                            simml.appendNewEvent(MMLEvent.PARAMETER, e.value2);
                            simml.appendNewEvent(MMLEvent.PARAMETER, lfoDelay);
                        } else {
                            simml.appendNewEvent(eventIDPMod, e.value2>>((v&4)?0:8));
                        }
                        break;
                    case MDXEvent.VOLUME_LFO:
                        v = e.value>>16;
                        simml.appendNewEvent(eventIDLFO, (e.value&0xffff)*75/tempo * ((v&3)?2:1));
                        simml.appendNewEvent(MMLEvent.PARAMETER, v&3);
                        if (lfoDelay) {
                            simml.appendNewEvent(eventIDAMod, 0);
                            simml.appendNewEvent(MMLEvent.PARAMETER, e.value2>>8);
                            simml.appendNewEvent(MMLEvent.PARAMETER, lfoDelay);
                        } else {
                            simml.appendNewEvent(eventIDAMod, e.value2>>8);
                        }
                        break;
                    case MDXEvent.FREQUENCY:
                        if (channelNumber == 7) {
                            /**/
                        } else 
                        if (channelNumber >= 8) {
                            simml.appendNewEvent(MMLEvent.NOTE, freqTable[e.value], 0);
                        }
                        break;
                    case MDXEvent.DATA_END:
                    case MDXEvent.SET_PCM8:
                        break;
                    case MDXEvent.SYNC_SEND:
                    case MDXEvent.SYNC_WAIT:
                    case MDXEvent.OPM_LFO:
                    default:
                        // not supported
                        break;
                    }
                    
                    lastNote = null;
                }
            }
        }
    }
}


