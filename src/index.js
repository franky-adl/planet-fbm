// ThreeJS and Third-party deps
import * as THREE from "three"
import * as dat from 'dat.gui'
import Stats from "three/examples/jsm/libs/stats.module"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls"

// Core boilerplate code deps
import { createCamera, createComposer, createRenderer, runApp, updateLoadingProgressBar, getDefaultUniforms } from "./core-utils"

// Other deps
import vertexShader from "./shaders/vertex.glsl"
import fragmentShader from "./shaders/fragment_gasplanet2.glsl"
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
  colorScheme: "monochromatic"
}
const uniforms = {
  ...getDefaultUniforms(),
  scale: { value: 5.0 }, // use 4.0 for gasplanet.glsl, 5 for gasplanet2.glsl
  shift: { value: 0.0 },
  waverScale: { value: 0.6 },
  waverFactor: { value: 0.9 },
  waverShift: { value: 1.6 },
  warperScale: { value: 2.0 },
  warperFactor: { value: 0.4 },
  pulserAmp: { value: 0.3 },
  pulserOffset: { value: 0.0 },
  hue: { value: 0.0 },
  colorScheme: { value: 1 },
  timeSpeed: { value: 0.03 }
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
    const guiCtrls = []
    // add a customAdd method that adds randMin and randMax params to the controller
    // so it's easier for us to implement a "randomize" button that randomizes each controller between its provided randMin and randMax
    dat.GUI.prototype.customAdd = (obj, prop, min, max, step, randMin, randMax) => {
      let controller = gui.add(obj, prop, min, max, step)
      controller.randMin = randMin || min
      controller.randMax = randMax || max
      return controller
    }
    guiCtrls.push(gui.customAdd(uniforms.scale, "value", 1, 10, 0.1, 3, 7).name("Base scale"))
    guiCtrls.push(gui.customAdd(uniforms.shift, "value", 0, 20, 0.1).name("Base shift"))
    guiCtrls.push(gui.customAdd(uniforms.waverScale, "value", 0.1, 3, 0.1, 0.3, 1.2).name("Waver scale"))
    guiCtrls.push(gui.customAdd(uniforms.waverFactor, "value", 0.0, 5, 0.01, 0.5, 1.5).name("Waver factor"))
    guiCtrls.push(gui.customAdd(uniforms.waverShift, "value", 0.0, 5, 0.01).name("Waver shift"))
    guiCtrls.push(gui.customAdd(uniforms.warperScale, "value", 0.1, 5, 0.1, 0.6, 2.6).name("Warper scale"))
    guiCtrls.push(gui.customAdd(uniforms.warperFactor, "value", 0.0, 5, 0.01, 0.2, 0.6).name("Warper factor"))

    guiCtrls.push(gui.customAdd(uniforms.pulserAmp, "value", 0.0, 5.0, 0.1, 0.0, 0.5).name("Pulser Amplitude"))
    guiCtrls.push(gui.customAdd(uniforms.pulserOffset, "value", 0.0, 10.0, 0.01, 0.0, 2.0).name("Pulser Offset"))

    guiCtrls.push(gui.customAdd(uniforms.hue, "value", 0.0, 1.0, 0.01).name("Hue"))
    gui.add(uniforms.timeSpeed, "value", 0.01, 0.5, 0.01).name("Time Speed")
    
    let schemeMap = {
      "monochromatic": 1,
      "analogous": 2,
      "reverse mono.": 3,
      "reverse ana.": 4,
    }
    let schemeCtrl = gui.add(params, "colorScheme", Object.keys(schemeMap)).name("Color Scheme").onChange((val) => {
      uniforms.colorScheme.value = schemeMap[val]
    })

    var randomProperty = (obj) => {
      var keys = Object.keys(obj)
      return keys[ keys.length * Math.random() << 0]
    }
    gui.add({
      randomize: () => {
        guiCtrls.forEach(ctrl => {
          if (ctrl.randMin || ctrl.randMax) {
            ctrl.setValue(ctrl.randMin + (ctrl.randMax - ctrl.randMin) * Math.random())
          }
        })
        schemeCtrl.setValue(randomProperty(schemeMap))
      }
    }, "randomize")

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
runApp(app, scene, renderer, camera, true, uniforms)
