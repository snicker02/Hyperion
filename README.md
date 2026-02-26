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
