/* ============================================================
   Interrupt Masking & Critical Section Safety Model
   Promela model for SPIN verification
   Authors: Hemang Rishi, Yash, Siddharth, Pranay, Hitanshu
   ============================================================ */

mtype = { IRQ, NMI };

chan irq_chan = [4] of { mtype };

bool interrupt_enable = true;
bool in_critical      = false;
bool irq_serviced     = false;
bool nmi_serviced     = false;

byte irq_count_gen    = 0;
byte irq_count_done   = 0;

/* ---- Device: generates maskable IRQ ---- */
proctype MaskableDevice()
{
    byte i = 0;
    do
    :: (i < 3) ->
        irq_chan ! IRQ;
        atomic { irq_count_gen++ };
        i++
    :: (i >= 3) -> break
    od
}

/* ---- Device: generates NMI (non-maskable) ---- */
proctype NMIDevice()
{
    irq_chan ! NMI
}

/* ---- CPU with masking logic ---- */
proctype CPU()
{
    mtype irq;
    do
    /* Enter critical section – mask interrupts */
    :: (!in_critical) ->
        atomic {
            interrupt_enable = false;
            in_critical      = true
        };
        skip;   /* critical section work */
        atomic {
            in_critical      = false;
            interrupt_enable = true
        }

    /* Service maskable IRQ only when enabled */
    :: (interrupt_enable && !in_critical && len(irq_chan) > 0) ->
        irq_chan ? irq;
        if
        :: (irq == IRQ) ->
            atomic {
                irq_serviced = true;
                irq_count_done++;
                irq_serviced = false
            }
        :: (irq == NMI) ->
            /* NMI always serviced regardless of mask */
            nmi_serviced = true;
            nmi_serviced = false
        fi

    /* Termination */
    :: (irq_count_done == irq_count_gen && irq_count_gen > 0
        && len(irq_chan) == 0) -> break
    od
}

init
{
    atomic {
        run CPU();
        run MaskableDevice();
        run NMIDevice()
    }
}

/* ---- LTL Properties ---- */

/* P8 – Safety: no IRQ is serviced while CPU is in critical section */
ltl p8_mask_safety {
    [] !(irq_serviced && in_critical)
}

/* P9 – Liveness: all maskable IRQs are eventually serviced */
ltl p9_irq_liveness {
    [] (irq_count_gen > 0 -> <> (irq_count_done == irq_count_gen))
}

/* P10 – Mutual exclusion: IRQ service and critical section never overlap */
ltl p10_mutual_exclusion {
    [] !(in_critical && irq_serviced)
}
