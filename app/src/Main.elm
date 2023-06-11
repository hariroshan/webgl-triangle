module Main exposing (main)

{-
   Rotating triangle, that is a "hello world" of the WebGL
-}

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 exposing (Vec3, vec3)
import Native exposing (Native)
import Native.Attributes as NA
import Native.Frame as Frame
import Native.Layout as Layout
import Native.Page as Page
import WebGL exposing (Mesh, Shader)


type NavPage
    = HomePage


type alias Flags =
    { width : Int
    , height : Int
    }


type alias Model =
    { rootFrame : Frame.Model NavPage
    , width : Int
    , height : Int
    , time : Float
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { rootFrame = Frame.init HomePage
      , time = 0
      , width = flags.width
      , height = flags.height
      }
    , Cmd.none
    )


type Msg
    = SyncFrame Bool
    | Tick Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SyncFrame bool ->
            ( { model | rootFrame = Frame.handleBack bool model.rootFrame }, Cmd.none )

        Tick tick ->
            ( { model | time = model.time + tick }, Cmd.none )


homePage : Model -> Native Msg
homePage model =
    Page.page SyncFrame
        []
        (Layout.stackLayout []
            [ WebGL.toHtml
                [ model.width |> String.fromInt |> NA.width
                , model.height |> String.fromInt |> NA.height
                ]
                [ WebGL.entity
                    vertexShader
                    fragmentShader
                    mesh
                    { perspective = perspective (model.time / 1000) }
                ]
            ]
        )


getPage : Model -> NavPage -> Native Msg
getPage model page =
    case page of
        HomePage ->
            homePage model


view : Model -> Native Msg
view model =
    model.rootFrame
        |> Frame.view [] (getPage model)


subscriptions : Model -> Sub Msg
subscriptions _ =
    onAnimationFrameDelta Tick


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


perspective : Float -> Mat4
perspective t =
    Mat4.mul
        (Mat4.makePerspective 45 1 0.01 100)
        (Mat4.makeLookAt (vec3 (4 * cos t) 0 (4 * sin t)) (vec3 0 0 0) (vec3 0 1 0))



-- Mesh


type alias Vertex =
    { position : Vec3
    , color : Vec3
    }


mesh : Mesh Vertex
mesh =
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0)
          , Vertex (vec3 1 1 0) (vec3 0 1 0)
          , Vertex (vec3 1 -1 0) (vec3 0 0 1)
          )
        ]



-- Shaders


type alias Uniforms =
    { perspective : Mat4 }


vertexShader : Shader Vertex Uniforms { vcolor : Vec3 }
vertexShader =
    [glsl|

        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        varying vec3 vcolor;

        void main () {
            gl_Position = perspective * vec4(position, 1.0);
            vcolor = color;
        }

    |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3 }
fragmentShader =
    [glsl|

        precision mediump float;
        varying vec3 vcolor;

        void main () {
            gl_FragColor = vec4(vcolor, 1.0);
        }

    |]
