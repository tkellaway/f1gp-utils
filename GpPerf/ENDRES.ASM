;**
;** File   : endres.asm
;** Author : TK
;** Date   :  8/06/94
;**
;** $Header:   F:/TK/GPPERF/VCS/ENDRES.AS_   1.1   15 Oct 1995 16:06:04   tk  $
;**
;** End of resident portion of TSR
;**

                name    endres
                title   'End of resident portion of TSR'

;*****************************************************************************
;**
;** Segments
;**

include segments.inc

;*****************************************************************************

TSR_CODE        segment

                public  end_resident_code
end_resident_code:
                dw      1234h
TSR_CODE        ends

TSR_DATA        segment

                public  end_resident_data
                public  end_resident

end_resident_data:
end_resident:   dw      55aah

TSR_DATA        ends

;*****************************************************************************

                end


