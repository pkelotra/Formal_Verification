import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch

fig, ax = plt.subplots(figsize=(16, 8))
ax.set_xlim(0, 16)
ax.set_ylim(0, 8)
ax.axis("off")
fig.patch.set_facecolor("white")

C = {"dev":"#7C3AED","nmi":"#DC2626","q":"#D97706","cpu":"#1D6FA4","h":"#15803D"}

def box(x, y, w, h, col, title, sub=""):
    ax.add_patch(FancyBboxPatch((x,y), w, h,
        boxstyle="round,pad=0.1,rounding_size=0.2",
        lw=2, edgecolor=col, facecolor=col+"18"))
    ty = y+h*0.62 if sub else y+h*0.5
    ax.text(x+w/2, ty, title, ha="center", va="center",
            fontsize=13, fontweight="bold", color=col)
    if sub:
        ax.text(x+w/2, y+h*0.3, sub, ha="center", va="center",
                fontsize=10, color="#555")

def arrow(x1,y1,x2,y2,lbl="",col="#333",dashed=False):
    ax.annotate("", xy=(x2,y2), xytext=(x1,y1),
        arrowprops=dict(arrowstyle="-|>", color=col, lw=1.8,
            linestyle=(0,(5,3)) if dashed else "-", mutation_scale=18))
    if lbl:
        ax.text((x1+x2)/2, (y1+y2)/2+0.22, lbl,
                ha="center", fontsize=10, color=col, fontweight="bold",
                bbox=dict(fc="white", ec="none", pad=1))

# ── Devices (left column) ────────────────────────────────────
box(0.3, 5.8, 2.4, 1.3, C["dev"],  "Timer Device",   "IRQ_TIMER | Pri 2")
box(0.3, 3.9, 2.4, 1.3, C["dev"],  "I/O Device",     "IRQ_IO | Pri 1")
box(0.3, 2.0, 2.4, 1.3, C["nmi"],  "NMI Source",     "IRQ_NMI | Pri 3")

# ── IRQ Queue ────────────────────────────────────────────────
box(4.0, 3.5, 2.6, 3.5, C["q"],    "IRQ Queue",      "chan[8]")

# ── CPU ──────────────────────────────────────────────────────
box(7.8, 3.5, 2.8, 3.5, C["cpu"],  "CPU Process",    "irq_enable\nin_critical")

# ── Dispatch ─────────────────────────────────────────────────
box(7.8, 1.2, 2.8, 1.6, C["q"],    "Dispatch Chan",  "chan[4]")

# ── Handler ──────────────────────────────────────────────────
box(12.2, 4.2, 2.8, 2.4, C["h"],   "IRQ Handler",    "dispatch & ACK")

# ── ACK ──────────────────────────────────────────────────────
box(12.2, 1.2, 2.8, 1.6, C["h"],   "ACK Channel",    "ack_chan[4]")

# ── Arrows ───────────────────────────────────────────────────
arrow(2.7, 6.45, 4.0, 6.6,  "IRQ",     C["dev"])
arrow(2.7, 4.55, 4.0, 5.5,  "IRQ",     C["dev"])
arrow(2.7, 2.65, 4.0, 4.2,  "flag",    C["nmi"])
arrow(6.6, 5.3,  7.8, 5.3,  "irq?",    C["q"])
arrow(9.2, 3.5,  9.2, 2.8,  "dispatch",C["cpu"])
arrow(10.6,2.0, 12.2,5.2,   "irq,prio",C["q"])
arrow(13.6,4.2, 13.6,2.8,   "ACK",     C["h"])

# NMI bypass dashed
arrow(2.7, 2.65, 7.8, 4.6,  "", C["nmi"], dashed=True)
ax.text(5.6, 3.3, "NMI bypass", ha="center", fontsize=9.5,
        color=C["nmi"], style="italic", fontweight="bold")

# ── Title ────────────────────────────────────────────────────
ax.text(8, 7.6, "Interrupt Handling System — Architecture",
        ha="center", fontsize=17, fontweight="bold", color="#1E293B")

# ── Legend ───────────────────────────────────────────────────
ax.legend(handles=[
    mpatches.Patch(fc=C["dev"]+"30", ec=C["dev"],  label="Devices"),
    mpatches.Patch(fc=C["nmi"]+"30", ec=C["nmi"],  label="NMI"),
    mpatches.Patch(fc=C["q"]+"30",   ec=C["q"],    label="Channels/Queue"),
    mpatches.Patch(fc=C["cpu"]+"30", ec=C["cpu"],  label="CPU"),
    mpatches.Patch(fc=C["h"]+"30",   ec=C["h"],    label="Handler"),
], loc="lower left", fontsize=10.5, framealpha=0.9, edgecolor="#ccc")

plt.tight_layout()
plt.savefig("fig1_architecture.png", dpi=200, bbox_inches="tight")
print("Done.")
