import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

fig, axes = plt.subplots(5, 1, figsize=(14, 8), sharex=True)
fig.patch.set_facecolor("white")
for ax in axes:
    ax.set_facecolor("white")

T = 20
time = np.arange(T)

# ── CPU always executing ───────────────────────────────────
cpu_exec = [1]*T

# ── Critical Section (subset of CPU) ───────────────────────
critical_sec = [0,0,1,1,1,0,0,1,1,0,0,0,1,1,0,0,1,1,0,0]

# ── Interrupt arrivals ─────────────────────────────────────
irq_timer = [0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
irq_io    = [0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0]
nmi       = [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0]

# ── Fix: NMI preempts critical section ─────────────────────
for i in range(T):
    if nmi[i] == 1:
        critical_sec[i] = 0  # pause critical section

# ── Combine TIMER + IO visually ────────────────────────────
timer_io = [max(t,i) for t,i in zip(irq_timer, irq_io)]

# ── Handler Logic (LOCAL MASKING MODEL) ────────────────────
handler_active = [0]*T

pending_timer = False
pending_io = False

for i in range(T):

    # NMI → immediate handling (highest priority)
    if nmi[i] == 1:
        handler_active[i] = 1
        continue

    # TIMER arrival
    if irq_timer[i] == 1:
        if critical_sec[i] == 0:
            handler_active[i] = 1
        else:
            pending_timer = True

    # IO arrival
    if irq_io[i] == 1:
        if critical_sec[i] == 0:
            handler_active[i] = 1
        else:
            pending_io = True

    # Handle pending interrupts when exiting critical section
    if critical_sec[i] == 0:
        if pending_timer:
            handler_active[i] = 1
            pending_timer = False
        elif pending_io:
            handler_active[i] = 1
            pending_io = False

# ── Colors (fixed) ─────────────────────────────────────────
colours = ["#4A90D9", "#E74C3C", "#9B59B6", "#E8A838", "#5BAD6F"]
labels  = [
    "CPU Executing",
    "Critical Section",
    "NMI",
    "TIMER / IO Arrival",
    "Handler Active"
]
rows = [cpu_exec, critical_sec, nmi, timer_io, handler_active]

# ── Plot ──────────────────────────────────────────────────
for ax, row, col, lab in zip(axes, rows, colours, labels):
    ax.fill_between(time, row, step="post", color=col, alpha=0.7)
    ax.step(time, row, where="post", color=col, lw=1.5)
    ax.set_ylim(-0.1, 1.4)
    ax.set_yticks([0, 1])
    ax.set_yticklabels(["OFF", "ON"], fontsize=8)
    ax.set_ylabel(lab, fontsize=8.5, rotation=0, ha="right",
                  labelpad=120, color=col, fontweight="bold")
    ax.axhline(0.5, color="#CCC", lw=0.6, linestyle="--")
    ax.spines[["top","right"]].set_visible(False)

# ── Interrupt markers ──────────────────────────────────────
arrival_times  = [2, 3, 4, 11, 15, 17]
arrival_labels = ["TIMER","NMI","IO","TIMER","IO","NMI"]
arrival_cols   = ["#E8A838","#9B59B6","#E8A838","#E8A838","#E8A838","#9B59B6"]

for t, lab, col in zip(arrival_times, arrival_labels, arrival_cols):
    axes[0].axvline(t, color=col, lw=1.4, linestyle=":", alpha=0.8)
    axes[0].text(t+0.1, 1.25, lab, fontsize=7, color=col, fontweight="bold")

axes[-1].set_xlabel("Time Steps (Promela simulation ticks)", fontsize=10)

fig.suptitle(
    "Interrupt Handling System – Execution Timeline\n(Local Masking: TIMER/IO blocked only in Critical Section, NMI always preempts)",
    fontsize=13, fontweight="bold", color="#2C3E50", y=1.02
)

plt.tight_layout()
plt.savefig("fig_final_correct.png", dpi=180, bbox_inches="tight", facecolor="white")

print("Saved: fig_final_correct.png")