// ThreeJS and Third-party deps
import * as THREE from "three"
import * as dat from 'dat.gui'
import Stats from "three/examples/jsm/libs/stats.module"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls"

// Core boilerplate code deps
import { createCamera, createComposer, createRenderer, runApp, updateLoadingProgressBar, getDefaultUniforms } from "./core-utils"

// Other deps
import vertexShader from "./shaders/vertex.glsl"
import fragmentShader from "./shaders/fragment_gasplanet.glsl"
import atmVertex from "./shaders/atmVertex.glsl"
import atmFragment from "./shaders/atmFragment.glsl"

global.THREE = THREE
// previously this feature is .legacyMode = false, see https://www.donmccurdy.com/2020/06/17/color-management-in-threejs/
// turning this on has the benefit of doing certain automatic conversions (for hexadecimal and CSS colors from sRGB to linear-sRGB)
THREE.ColorManagement.enabled = true

/**************************************************
 * 0. Tweakable parameters for the scene
 *************************************************/
const params = {
  // general scene params
}
const uniforms = {
  ...getDefaultUniforms(),
  scale: { value: 4.0 },
  shift: { value: 100.0 },
  rot_angle: { value: 0.1 },
  octaves: { value: 5 },
  freq_up_factor: { value: 2.0 },
  amp_down_factor: { value: 0.6 },
}


/**************************************************
 * 1. Initialize core threejs components
 *************************************************/
// Create the scene
let scene = new THREE.Scene()

// Create the renderer via 'createRenderer',
// 1st param receives additional WebGLRenderer properties
// 2nd param receives a custom callback to further configure the renderer
let renderer = createRenderer({ antialias: true }, (_renderer) => {
  // best practice: ensure output colorspace is in sRGB, see Color Management documentation:
  // https://threejs.org/docs/#manual/en/introduction/Color-management
  _renderer.outputColorSpace = THREE.SRGBColorSpace
})

// Create the camera
// Pass in fov, near, far and camera position respectively
let camera = createCamera(45, 1, 1000, { x: 0, y: 0, z: 6 })


/**************************************************
 * 2. Build your scene in this threejs app
 * This app object needs to consist of at least the async initScene() function (it is async so the animate function can wait for initScene() to finish before being called)
 * initScene() is called after a basic threejs environment has been set up, you can add objects/lighting to you scene in initScene()
 * if your app needs to animate things(i.e. not static), include a updateScene(interval, elapsed) function in the app as well
 *************************************************/
let app = {
  async initScene() {
    // OrbitControls
    this.controls = new OrbitControls(camera, renderer.domElement)
    this.controls.enableDamping = true

    await updateLoadingProgressBar(0.1)

    this.geometry = new THREE.SphereGeometry(2, 64, 64)
    this.material = new THREE.ShaderMaterial({
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      uniforms: uniforms
    })
    this.mesh = new THREE.Mesh(this.geometry, this.material)
    scene.add(this.mesh)

    this.atm = new THREE.SphereGeometry(2.38, 64, 64)
    this.atmMat = new THREE.ShaderMaterial({
      vertexShader: atmVertex,
      fragmentShader: atmFragment,
      uniforms: uniforms,
      blending: THREE.AdditiveBlending, // works better than setting transparent: true, because it avoids a weird dark edge around the earth
      side: THREE.BackSide
    })
    this.atmMesh = new THREE.Mesh(this.atm, this.atmMat)
    scene.add(this.atmMesh)

    // GUI controls
    const gui = new dat.GUI()
    gui.add(uniforms.scale, "value", 1, 10, 0.1).name("scale")
    gui.add(uniforms.shift, "value", 0, 200, 1).name("shift")
    gui.add(uniforms.rot_angle, "value", 0, 3.15, 0.05).name("rotation angle")
    gui.add(uniforms.octaves, "value", 1, 10, 1).name("octaves")
    gui.add(uniforms.freq_up_factor, "value", 1, 5, 0.1).name("frequency up")
    gui.add(uniforms.amp_down_factor, "value", 0.05, 0.95, 0.05).name("amplitude down")

    // Stats - show fps
    this.stats1 = new Stats()
    this.stats1.showPanel(0) // Panel 0 = fps
    this.stats1.domElement.style.cssText = "position:absolute;top:0px;left:0px;"
    // this.container is the parent DOM element of the threejs canvas element
    this.container.appendChild(this.stats1.domElement)

    await updateLoadingProgressBar(1.0, 100)
  },
  // @param {number} interval - time elapsed between 2 frames
  // @param {number} elapsed - total time elapsed since app start
  updateScene(interval, elapsed) {
    this.controls.update()
    this.stats1.update()
  }
}

/**************************************************
 * 3. Run the app
 * 'runApp' will do most of the boilerplate setup code for you:
 * e.g. HTML container, window resize listener, mouse move/touch listener for shader uniforms, THREE.Clock() for animation
 * Executing this line puts everything together and runs the app
 * ps. if you don't use custom shaders, pass undefined to the 'uniforms'(2nd-last) param
 * ps. if you don't use post-processing, pass undefined to the 'composer'(last) param
 *************************************************/
runApp(app, scene, renderer, camera, true, uniforms, undefined)
