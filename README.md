<html>
<body>
<!--StartFragment--><h1 class="text-text-100 mt-3 -mb-1 text-[1.375rem] font-bold">Hyperion v3.0 — <em>Archon &amp; Shapes Update</em></h1>
<blockquote class="ml-2 border-l-4 border-border-300/10 pl-4 text-text-300">
<p class="font-claude-response-body break-words whitespace-normal leading-[1.7]">An original fractal explorer built in Godot 4, featuring raymarched 4D fractals, flythrough animation, video export, and now — living architecture.</p>
</blockquote>
<hr class="border-border-200 border-t-0.5 my-3 mx-1.5">
<h2 class="text-text-100 mt-3 -mb-1 text-[1.125rem] font-bold">✨ What's New in 3.0</h2>
<h3 class="text-text-100 mt-2 -mb-1 text-base font-bold">🏛️ The Archon Fractal</h3>
<p class="font-claude-response-body break-words whitespace-normal leading-[1.7]">Archon is an entirely original fractal formula developed for Hyperion. It uses recursive 4D space to generate impossible architectural structures — colonnades, arched ruins, cathedral vaults, and labyrinthine city blocks that repeat infinitely inward.</p>
<p class="font-claude-response-body break-words whitespace-normal leading-[1.7]"><strong>Two distinct modes:</strong></p>
<ul class="[li_&amp;]:mb-0 [li_&amp;]:mt-1 [li_&amp;]:gap-1 [&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc flex flex-col gap-1 pl-8 mb-3">
<li class="whitespace-normal break-words pl-2"><strong>Organic</strong> — smooth sphere inversions and trig folds produce flowing, swirling forms with dramatic depth</li>
<li class="whitespace-normal break-words pl-2"><strong>City</strong> — hard box folding (Mandelbox-style) replaces smooth curves with sharp stone slabs, rectangular windows, and brutalist block geometry</li>
</ul>
<p class="font-claude-response-body break-words whitespace-normal leading-[1.7]"><strong>Full parameter suite:</strong></p>
<div class="overflow-x-auto w-full px-2 mb-6">
Group | Parameters
-- | --
Main | Scale, Iterations, Bailout, Tower Bias, Archon Constant (XYZW)
Spin-Warp | Spin Strength, Spin Axis (Columns / Arches / Rings), Arch Frequency, Arch Depth, Arch Axis (Doorways / Windows / Tunnels)
Wave Shape | Wave Type (Sine, Triangle, Square, Sawtooth, Bounce), Wave Blend
Inversion | Inv Radius, Inv Strength
4D Transform | Rotation Angle, W Rotation Speed (animated)
Rendering | Max Steps, Detail
Julia | Julia Mode, Julia Seed (XYZW), Julia Morph

</div>
<hr class="border-border-200 border-t-0.5 my-3 mx-1.5">
<h2 class="text-text-100 mt-3 -mb-1 text-[1.125rem] font-bold">📽️ Flythrough &amp; Video Export</h2>
<p class="font-claude-response-body break-words whitespace-normal leading-[1.7]">Record multi-waypoint camera paths with smooth parameter interpolation. All shader values tween between waypoints. Export to MP4 via FFmpeg (must be installed separately).</p>
<hr class="border-border-200 border-t-0.5 my-3 mx-1.5">
<h2 class="text-text-100 mt-3 -mb-1 text-[1.125rem] font-bold">🛠️ Requirements</h2>
<ul class="[li_&amp;]:mb-0 [li_&amp;]:mt-1 [li_&amp;]:gap-1 [&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc flex flex-col gap-1 pl-8 mb-3">
<li class="whitespace-normal break-words pl-2"><strong>Godot 4.5+</strong></li>
<li class="whitespace-normal break-words pl-2"><strong>Vulkan-capable GPU</strong> (tested on RTX 4090, works on lower-end cards with reduced MaxSteps)</li>
<li class="whitespace-normal break-words pl-2"><strong>FFmpeg</strong> (optional, for video export)</li>
</ul>
<hr class="border-border-200 border-t-0.5 my-3 mx-1.5">
<h2 class="text-text-100 mt-3 -mb-1 text-[1.125rem] font-bold">📝 Notes</h2>
<ul class="[li_&amp;]:mb-0 [li_&amp;]:mt-1 [li_&amp;]:gap-1 [&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc flex flex-col gap-1 pl-8 mb-3">
<li class="whitespace-normal break-words pl-2">Bristorbrot code updated to correct code from inventor Doug Bristor</li>
<li class="whitespace-normal break-words pl-2">Archon presets save and restore camera position, rotation, and all shader parameters</li>
<li class="whitespace-normal break-words pl-2">City mode starting values: Scale <code class="bg-text-200/5 border border-0.5 border-border-300 text-danger-000 whitespace-pre-wrap rounded-[0.4rem] px-1 py-px text-[0.9rem]">2.0</code>, ArchonConstant <code class="bg-text-200/5 border border-0.5 border-border-300 text-danger-000 whitespace-pre-wrap rounded-[0.4rem] px-1 py-px text-[0.9rem]">(1.0, 1.0, 1.0, 0.5)</code>, InvRadius <code class="bg-text-200/5 border border-0.5 border-border-300 text-danger-000 whitespace-pre-wrap rounded-[0.4rem] px-1 py-px text-[0.9rem]">1.0</code>, InvStrength <code class="bg-text-200/5 border border-0.5 border-border-300 text-danger-000 whitespace-pre-wrap rounded-[0.4rem] px-1 py-px text-[0.9rem]">0.5</code>, Wave Type <code class="bg-text-200/5 border border-0.5 border-border-300 text-danger-000 whitespace-pre-wrap rounded-[0.4rem] px-1 py-px text-[0.9rem]">Square</code> for rectangular windows</li>
<li class="whitespace-normal break-words pl-2">Organic mode default produces the signature swirling purple vortex forms</li>
</ul>
<hr class="border-border-200 border-t-0.5 my-3 mx-1.5">
<h2 class="text-text-100 mt-3 -mb-1 text-[1.125rem] font-bold">🙏 Credits</h2>
<p class="font-claude-response-body break-words whitespace-normal leading-[1.7]">Hyperion is an original project by <strong>Brad Stefanov and collaboratively with Claude and Gemini </strong>.<br>
Archon fractal formula conceived and developed collaboratively.<br>
Built with <a class="underline underline underline-offset-2 decoration-1 decoration-current/40 hover:decoration-current focus:decoration-current" href="https://godotengine.org">Godot Engine</a> 4.5.</p><!--EndFragment-->
</body>
</html>


-------------------------------------------------
# Hyperion v2.0

Hyperion is a high-performance, real-time 4D fractal cinematography suite built in the Godot Engine. Version 2.0 represents a complete overhaul of the engine's core, focusing on mathematical diversity and cinematic stability.

## 🚀 What's New in V2.0

### 🌌 New Mathematical Engines
* **Amazing Surf:** Explore complex 4D topology with dedicated controls for power, scaling, and surface roughness.
* **BristorBrot:** Implementation of Doug Bristor’s "Entangled" math, featuring advanced warp parameters and high-dimensional rotation logic.
* **KIFS Kaleidoscope:** A new symmetry suite with XY, XZ, and YZ axis selectors and per-axis "Twist" controls for infinite geometric complexity.

### 🎬 Cinematic Flythrough System
The animation engine has been rebuilt from the ground up:
* **Quaternion Smoothing:** Uses Spherical Linear Interpolation (SLERP) to ensure camera rotations are fluid and natural.
* **Type-Safe Morphing:** Intelligent transition logic that bridges the gap between Vector3 and Vector4 shader parameters.
* **Auto-Pilot Logic:** Manual controls automatically yield to the animation system for zero-jitter cinematic playback.

### 💾 Preset & Data Management
* **Save/Load System:** Full state persistence. Save your camera position, fractal parameters, and color palettes to `.cfg` files.
* **Real-time UI Sync:** Sliders and toggles now actively track shader changes during flythroughs, providing instant visual feedback.

---

## 🛠 Features
* **Multiple Shaders:** Mandelbox 4D, Menger 4D, Amazing Surf, and BristorBrot.
* **4D Slicing:** Dynamically navigate the W-axis to see the fractal's cross-section change in real-time.
* **Symmetry Folding:** Advanced Absolute and Swap toggles for X, Y, and Z planes.
* **Video Export:** Built-in frame capture pipeline (optimized for high-end GPUs like the RTX 4090).

## ⌨️ Controls
* **WASD + Mouse:** Standard Pilot Movement.
* **[P]:** Add Waypoint to the current path.
* **[H]:** Toggle UI visibility for a clean view.
* **[F2]:** Open Runtime Debug Tools.

## ⚙️ Requirements
* **Engine:** Godot 4.3 or higher.
* **GPU:** Dedicated GPU with Vulkan support (Forward+ rendered).
----------------------------------------------------------------------------

Hyperion V1.1

fixed bugs with image saving
----------------------------------------------------------------------------
Hyperion V1.0 - 4D Fractal Explorer
Hyperion is a high-performance generative art tool built in Godot for exploring and recording complex 4D fractals, including Mandelbox and Menger variations.

🚀 Features
Dual Fractal Engines: Seamlessly switch between Mandelbox and Menger4D architectures.

Deep 4D Controls: Manipulate the W-slice, rotation, and hollowing parameters in real-time.

Advanced Symmetry: Toggle folding and symmetry across X, Y, and Z axes with custom strength sliders.

Mirrored Panorama Backgrounds: Upload any image to create a seamless, horizontally mirrored 3D sky environment.

Cinematic Animation System: Set waypoints to record smooth, multi-segment flythroughs.

High-Fidelity Recording: Frame-locked 30 FPS PNG sequence export for perfectly smooth video production.

⌨️ Controls & Hotkeys
W/A/S/D + Mouse: Fly through the fractal.

H: Toggle UI visibility for a clean view.

R: Stop recording (saves currently captured frames to user://recordings).

F2: Toggle Debug Tools.

📸 Recording & Export
To ensure the highest quality, Hyperion captures a sequence of PNG frames.

Set your waypoints and test your path.

Press Play Animation.

Press Start Recording.

Once finished, press R to stop.

Hyperion will prompt you to save the final video; ensure you have FFmpeg installed on your system path for the automatic stitcher to work.

You must have FFMPG installed to save animations https://www.ffmpeg.org/www.ffmpeg.org/ 

For program to save as mp4 you must add FFMPEG to system path. You only have to do this step one time.  Instructions are here. https://docs.google.com/document/d/1bv4__JFZX7mvYdIsItGDAiIU2nbfe3P5ZYgVwHXHJXg/edit?usp=sharing



Program created by Brad Stefanov with assistance from Gemini and Claude
