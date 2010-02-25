//----------------------------------------------------------------------------------------------------
// class for SiOPM PCM data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.sequencer.SiMMLTable;
    
    
    /** PCM data class */
    public class SiOPMWavePCMTable extends SiOPMWaveBase
    {
    // valiables
    //----------------------------------------
        /** PCM wave data assign table for each note. */
        private var _table:Vector.<SiOPMWavePCMData>;
        
        
        
        
    // constructor
    //----------------------------------------
        /** Constructor */
        function SiOPMWavePCMTable()
        {
            super(SiMMLTable.MT_PCM);
            _table = new Vector.<SiOPMWavePCMData>(SiOPMTable.NOTE_TABLE_SIZE);
            clear();
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** Clear all of the table.
         *  @param pcmData SiOPMWavePCMData to fill with.
         *  @return this instance
         */
        public function clear(pcmData:SiOPMWavePCMData = null) : SiOPMWavePCMTable
        {
            for (var i:int = 0; i<SiOPMTable.NOTE_TABLE_SIZE; i++) _table[i] = pcmData;
            return this;
        }
        
        
        /** Set sample data.
         *  @param pcmData assignee SiOPMWavePCMData
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @return assigned PCM data (same as pcmData passed as the 1st argument.)
         */
        public function setSample(pcmData:SiOPMWavePCMData, keyRangeFrom:int=0, keyRangeTo:int=-1) : SiOPMWavePCMData
        {
            if (keyRangeFrom<0) keyRangeFrom = 0;
            if (keyRangeTo>127) keyRangeTo = 127;
            if (keyRangeTo==-1) keyRangeTo = keyRangeFrom;
            if (keyRangeFrom>127 || keyRangeTo<0 || keyRangeTo<keyRangeFrom) throw new Error("SiOPMWavePCMTable error; Invalid key range");
            for (var i:int=keyRangeFrom; i<=keyRangeTo; i++) _table[i] = pcmData;
            return pcmData;
        }
        
        
        /** Get sample data.
         *  @param note Note number (0-127).
         *  @return assigned SiOPMWaveSamplerData
         */
        public function getSample(note:int) : SiOPMWavePCMData
        {
            return _table[note];
        }
        
        
        /** @private [internal use] free all */
        _siopm_module_internal function _free() : void
        {
        }
    }
}

