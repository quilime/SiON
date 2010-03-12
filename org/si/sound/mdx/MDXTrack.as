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
        /** channel number */
        public var channelNumber:int;
        /** owner MDXData */
        public var owner:MDXData;
        
        
        
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
        function MDXTrack(owner:MDXData, channelNumber:int)
        {
            this.owner = owner;
            this.channelNumber = channelNumber;
            sequence = new Vector.<MDXEvent>();
            segnoPointer = null;
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : MDXTrack
        {
            sequence.length = 0;
            segnoPointer = null;
            return this;
        }
        
        
        /** Load track from byteArray. */
        public function loadBytes(bytes:ByteArray) : MDXTrack
        {
            clear();
            
            var code:int, v:int, clock:uint, pos:int, mem:Array=[], exitLoop:Boolean = false;
            clock = 0;
            
            while (!exitLoop && bytes.bytesAvailable>0) {
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
                    case MDXEvent.FADEOUT:
                        newEvent(code, bytes.readUnsignedByte(), bytes.readUnsignedByte());
                        break;
                    //----- 1 operand
                    case MDXEvent.VOICE:
                    case MDXEvent.PAN:
                    case MDXEvent.VOLUME:
                    case MDXEvent.GATE:
                    case MDXEvent.KEY_ON_DELAY:
                    case MDXEvent.FREQUENCY:
                    case MDXEvent.LFO_DELAY:
                        newEvent(code, bytes.readUnsignedByte());
                        break;
                    //----- no operands
                    case MDXEvent.VOLUME_DEC:
                    case MDXEvent.VOLUME_INC:
                    case MDXEvent.SLUR:
                    case MDXEvent.SET_PCM8:
                        newEvent(code);
                        break;
                    //----- 1 WORD
                    case MDXEvent.DETUNE:
                    case MDXEvent.PORTAMENT:
                        newEvent(code, bytes.readShort()); //...short?
                        break;
                    //----- REPEAT
                    case MDXEvent.REPEAT_BEGIN:
                        newEvent(code, bytes.readUnsignedByte(), bytes.readUnsignedByte());
                        break;
                    case MDXEvent.REPEAT_END:
                        v = pos+(bytes.readShort()); // REPEAT_BEGIN
                        newEvent(code, v);
                        break;
                    case MDXEvent.REPEAT_BREAK:
                        v = pos+(bytes.readShort()+2); // REPEAT_END
                        newEvent(code, v);
                        break;
                    //----- others
                    case MDXEvent.TIMERB:
                    case MDXEvent.SYNC_SEND:
                        v = bytes.readUnsignedByte();
                        owner.globalEvents.push(newEvent(code, v));
                        break;
                    case MDXEvent.SYNC_WAIT:
                        owner.globalEvents.push(newEvent(code));
                        break;
                    case MDXEvent.PITCH_LFO:
                    case MDXEvent.VOLUME_LFO:
                        v = bytes.readUnsignedByte();
                        if (v == 0x80 || v == 0x81) newEvent(code, v<<24);
                        else newEvent(code, (v<<16) | bytes.readUnsignedShort(), bytes.readUnsignedShort());
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
            
            
            function newEvent(type:int, data:int=0, data2:int=0, deltaClock:int=0) : MDXEvent {
                var inst:MDXEvent = new MDXEvent(type, data, data2, clock, deltaClock);
                sequence.push(inst);
                mem[pos] = inst;
                return inst;
            }
            
            return this;
        }
        
        
        /** @private [internal] construct MMLSequence */
        internal function _constructMMLSequence(mmlseq:MMLSequence) : void
        {
            if (SiONDriver.mutex == null) return;
            
            var i:int, v:int, imax:int, e:MDXEvent, me:MMLEvent, sequencer:SiMMLSequencer = SiONDriver.mutex.sequencer,  
                panTable:Array = [4,0,8,4], freqTable:Array = [18,23,30,35,42], adpcmFreq:int = 4, adpcmID:int = -1,
                repeatStac:Array = [], lastNoteMDX:MDXEvent, lastNoteMML:MMLEvent, 
                lfoDelay:int=0, lfofq:int=0, lfows:int=2, mp:int=0, ma:int=0, 
                eventIDFadeOut:int = sequencer.getEventID("@fadeout"),
                eventIDPan:int     = sequencer.getEventID("p"),
                eventIDPShift:int  = sequencer.getEventID("k"),
                eventIDLFO:int     = sequencer.getEventID("@lfo"),
                eventIDAMod:int    = sequencer.getEventID("ma"),
                eventIDPMod:int    = sequencer.getEventID("mp"),
                eventIDIndex:int   = sequencer.getEventID("i");
            
                
            mmlseq.initialize();
            if (channelNumber < 8) mmlseq.appendNewEvent(MMLEvent.MOD_TYPE, 6); // use FM voice
            else                   mmlseq.appendNewEvent(MMLEvent.MOD_TYPE, 7); // use PCM voice
            
            imax = sequence.length;
            for (i=0; i<imax; i++) {
                e = sequence[i];
                if (segnoPointer === e) mmlseq.appendNewEvent(MMLEvent.REPEAT_ALL, 0);
                if (e.type < 0x80) {
                    mmlseq.appendNewEvent(MMLEvent.REST, 0, e.deltaClock*10);
                } else if (e.type < 0xe0) {
                     lastNoteMDX = e;
                    if (channelNumber < 8) {
                        lastNoteMML = mmlseq.appendNewEvent(MMLEvent.NOTE, e.data+12, e.deltaClock*10); // use FM voice
                    } else {
                        // use PCM voice
                        if (adpcmID != e.data) {
                            adpcmID = e.data;
                            mmlseq.appendNewEvent(MMLEvent.MOD_PARAM, adpcmID);
                        }
                        lastNoteMML = mmlseq.appendNewEvent(MMLEvent.NOTE, freqTable[adpcmFreq], e.deltaClock*10); 
                    }
                } else {
                    switch(e.type) {
                    case MDXEvent.REGISTER:
                        mmlseq.appendNewEvent(MMLEvent.REGISTER, (e.data << 8) | e.data2);
                        break;
                    case MDXEvent.FADEOUT:
                        mmlseq.appendNewEvent(eventIDFadeOut, e.data2);
                        break;
                    case MDXEvent.VOICE:
                        mmlseq.appendNewEvent(MMLEvent.MOD_PARAM, e.data);
                        break;
                    case MDXEvent.PAN:
                        if (e.data == 0) mmlseq.appendNewEvent(MMLEvent.VOLUME, 0);
                        else {
                            mmlseq.appendNewEvent(MMLEvent.VOLUME, 16);
                            mmlseq.appendNewEvent(eventIDPan, panTable[e.data]);
                        }
                        break;
                    case MDXEvent.VOLUME:
                        if (e.data < 16) mmlseq.appendNewEvent(MMLEvent.FINE_VOLUME, e.data<<3);
                        else mmlseq.appendNewEvent(MMLEvent.FINE_VOLUME, e.data & 127);
                        break;
                    case MDXEvent.GATE:
                        if (e.data < 9) {
                            mmlseq.appendNewEvent(MMLEvent.QUANT_RATIO, e.data);
                            mmlseq.appendNewEvent(MMLEvent.QUANT_COUNT, 0);
                        } else {
                            mmlseq.appendNewEvent(MMLEvent.QUANT_RATIO, 8);
                            mmlseq.appendNewEvent(MMLEvent.QUANT_COUNT, (256-e.data)*10);
                        }
                        break;
                    case MDXEvent.KEY_ON_DELAY:
                        mmlseq.appendNewEvent(MMLEvent.KEY_ON_DELAY, e.data*10);
                        break;
                    case MDXEvent.VOLUME_DEC:
                        mmlseq.appendNewEvent(MMLEvent.VOLUME_SHIFT, -1);
                        break;
                    case MDXEvent.VOLUME_INC:
                        mmlseq.appendNewEvent(MMLEvent.VOLUME_SHIFT, 1);
                        break;
                    case MDXEvent.SLUR:
                        if (lastNoteMML) {
                            mmlseq.appendNewEvent(MMLEvent.SLUR_WEAK, 0, lastNoteMML.length);
                            lastNoteMML.length = 0;
                        }
                        break;
                    case MDXEvent.REPEAT_BEGIN:
                        repeatStac.unshift(mmlseq.appendNewEvent(MMLEvent.REPEAT_BEGIN, e.data));
                        break;
                    case MDXEvent.REPEAT_BREAK:
                        me = mmlseq.appendNewEvent(MMLEvent.REPEAT_BREAK, 0);
                        me.jump = repeatStac[0];
                        break;
                    case MDXEvent.REPEAT_END:
                        me = mmlseq.appendNewEvent(MMLEvent.REPEAT_END, 0);
                        me.jump = repeatStac.shift();
                        me.jump.jump = me;
                        break;
                    case MDXEvent.DETUNE:
                        mmlseq.appendNewEvent(eventIDPShift, e.data);
                        break;
                    case MDXEvent.PORTAMENT:
                        if (lastNoteMML) {
                            v = lastNoteMML.data + (e.data * (e.clock - lastNoteMDX.clock) + 8192)/16384;
                            if (v<0) v=0;
                            else if (v>127) v=127;
                            mmlseq.appendNewEvent(MMLEvent.PITCHBEND, 0, lastNoteMML.length);
                            lastNoteMML.length = 0;
                            mmlseq.appendNewEvent(MMLEvent.NOTE, v, 0);
                        }
                        break;
                    case MDXEvent.LFO_DELAY:
                        lfoDelay = e.data*75/owner.bpm;
                        break;
                    case MDXEvent.PITCH_LFO:
                        if (e.data>>24) {
                            if ((e.data>>24) == 0x80) mmlseq.appendNewEvent(eventIDPMod, 0);
                            else _mod(eventIDPMod, mp);
                        } else {
                            lfows = (e.data>>16)&3;
                            lfofq = (e.data&0xffff)*75/owner.bpm * ((lfows)?2:1);
                            mp = e.data2>>((e.data&0x40000)?0:8);
                            _mod(eventIDPMod, mp);
                        }
                        break;
                    case MDXEvent.VOLUME_LFO:
                        if (e.data>>24) {
                            if ((e.data>>24) == 0x80) mmlseq.appendNewEvent(eventIDAMod, 0);
                            else _mod(eventIDPMod, ma);
                        } else {
                            lfows = (e.data>>16)&3;
                            lfofq = (e.data&0xffff)*75/owner.bpm * ((lfows)?2:1);
                            ma = e.data2>>8;
                            _mod(eventIDAMod, ma);
                        }
                        break;
                    case MDXEvent.FREQUENCY:
                        if (channelNumber == 7) {
                            /**/
                        } else 
                        if (channelNumber >= 8) {
                            adpcmFreq = e.data;
                        }
                        break;
                    case MDXEvent.DATA_END:
                    case MDXEvent.SET_PCM8:
                    case MDXEvent.TIMERB:
                        break;
                    case MDXEvent.SYNC_SEND:
                    case MDXEvent.SYNC_WAIT:
                    case MDXEvent.OPM_LFO:
                    default:
                        // not supported
                        break;
                    }
                }
            }
            
            
            function _mod(eventID:int, data:int) : void {
                mmlseq.appendNewEvent(eventID, lfofq);
                mmlseq.appendNewEvent(MMLEvent.PARAMETER, lfows);
                if (lfoDelay) {
                    mmlseq.appendNewEvent(eventID, 0);
                    mmlseq.appendNewEvent(MMLEvent.PARAMETER, data);
                    mmlseq.appendNewEvent(MMLEvent.PARAMETER, lfoDelay);
                } else {
                    mmlseq.appendNewEvent(eventID, data);
                }
            }
        }
    }
}


