//----------------------------------------------------------------------------------------------------
// SiMML data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.sequencer.base.MMLData;
    import org.si.utils.SLLint;
    
    
    
    /** SiMML data class. */
    public class SiMMLData extends MMLData
    {
    // valiables
    //----------------------------------------
        /** envelop tables */
        protected var _envelops:Vector.<SiMMLEnvelopTable>;
        /** voice data */
        protected var _voices:Vector.<SiMMLVoice>;
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor. */
        function SiMMLData()
        {
            _envelops = new Vector.<SiMMLEnvelopTable>(SiMMLTable.ENV_TABLE_MAX);
            _voices   = new Vector.<SiMMLVoice>(SiMMLTable.VOICE_MAX);
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Clear all parameters and free all sequence groups. */
        override public function clear() : void
        {
            super.clear();
            var i:int, imax:int;
            imax = _envelops.length;
            for (i=0; i<imax; i++) _envelops[i] = null;
            imax = _voices.length;
            for (i=0; i<imax; i++) _voices[i] = null;
        }
        
        
        /** Set envelop table data refered by &#64;&#64;,na,np,nt,nf,_&#64;&#64;,_na,_np,_nt and _nf.
         *  @param index envelop table number.
         *  @param envelop envelop table.
         */
        public function setEnvelopTable(index:int, envelop:SiMMLEnvelopTable) : void
        {
            if (index >= 0 && index < SiMMLTable.ENV_TABLE_MAX) _envelops[index] = envelop;
        }
        
        
        /** Set wave table data refered by %6.
         *  @param index wave table number.
         *  @param voice voice to register.
         */
        public function setVoice(index:int, voice:SiMMLVoice) : void
        {
            if (index >= 0 && index < SiMMLTable.VOICE_MAX) {
                if (!voice._isSuitableForFMVoice) throw errorNotGoodFMVoice();
                 _voices[index] = voice;
            }
        }
        
        
        
        
    // internal function
    //--------------------------------------------------
        /** @private [internal use] Register all tables before processing audio. */
        override public function _regiterTables() : void
        {
            super._regiterTables();
            SiMMLTable.instance.stencilEnvelops = _envelops;
            SiMMLTable.instance.stencilVoices   = _voices;
        }
        
        
        /** @private [internal use] Set envelop table data */
        internal function _setEnvelopTable(index:int, head:SLLint, tail:SLLint) : void
        {
            var t:SiMMLEnvelopTable = new SiMMLEnvelopTable();
            t._initialize(head, tail);
            _envelops[index] = t;
        }
        
        
        /** @private [internal use] Get channel parameter */
        internal function _getSiOPMChannelParam(index:int) : SiOPMChannelParam
        {
            var v:SiMMLVoice = new SiMMLVoice();
            v.channelParam = new SiOPMChannelParam();
            _voices[index] = v;
            return v.channelParam;
        }
        
        
        
        
    // error
    //----------------------------------------
        private function errorNotGoodFMVoice() : Error {
            return new Error("SiONDriver error; Cannot register the voice.");
        }
    }
}

