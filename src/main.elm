module Main exposing (Model, Msg, init, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (disabled, style)
import Html.Events exposing (onClick)
import Random exposing (Seed, generate)
import Random.List exposing (shuffle)
import SimpleGraph exposing (GraphAttributes, Option(..), barChart, lineChart)
import SingleSlider exposing (..)
import Time exposing (Posix, millisToPosix)



--DATA


insertionSort : List Int -> List Int
insertionSort list =
    case list of
        [] ->
            []

        [ _ ] ->
            list

        first :: (second :: rest) ->
            if first < second then
                first :: insertionSort (second :: rest)

            else
                second :: insertionSort (first :: rest)


selectionSort : List Int -> List Int
selectionSort list =
    case list of
        [] ->
            []

        [ _ ] ->
            list

        first :: (second :: rest) ->
            if List.minimum list == Just first then
                first :: selectionSort (second :: rest)

            else
                second :: selectionSort (first :: rest)


quickSort : List Int -> List Int
quickSort list =
    case list of
        [] ->
            []

        pivot :: rest ->
            let
                smaller =
                    List.filter (\n -> n <= pivot) rest

                bigger =
                    List.filter (\n -> n > pivot) rest
            in
            if List.sort smaller == smaller then
                smaller ++ [ pivot ] ++ quickSort bigger

            else
                quickSort smaller ++ [ pivot ] ++ bigger


mergeSort list =
    case list of
        [] ->
            list

        [ _ ] ->
            list

        _ ->
            let
                ( halfOne, halfTwo ) =
                    split list
            in
            merge (mergeSort halfOne) (mergeSort halfTwo)


split : List Int -> ( List Int, List Int )
split list =
    splitHelp list 1 [] []


splitHelp : List Int -> Int -> List Int -> List Int -> ( List Int, List Int )
splitHelp list num halfOne halfTwo =
    case list of
        [] ->
            ( halfOne, halfTwo )

        first :: rest ->
            if (num // 2) == 1 then
                splitHelp rest (num + 1) (first :: halfOne) halfTwo

            else
                splitHelp rest (num + 1) halfOne (first :: halfTwo)


merge : List Int -> List Int -> List Int
merge listOne listTwo =
    case ( listOne, listTwo ) of
        ( _, [] ) ->
            listOne

        ( [], _ ) ->
            listTwo

        ( frontOne :: restOne, frontTwo :: restTwo ) ->
            if frontOne < frontTwo then
                frontOne :: merge restOne listTwo

            else
                frontTwo :: merge restTwo listOne


floatedList : List Int -> List Float
floatedList list =
    List.map (\n -> toFloat n) list


adjustedGraphAttributes : Model -> GraphAttributes
adjustedGraphAttributes model =
    { graphHeight = 300
    , graphWidth = 900
    , options =
        [ Color "#87e5cb"
        , YTickmarks 6
        , XTickmarks 1
        , Scale 1.0 1.0
        , DeltaX model.deltaX
        ]
    }


dummyPosix : Posix
dummyPosix =
    millisToPosix 0


stateString : State -> String
stateString state =
    case state of
        Stop ->
            "Stop"

        Randomizing ->
            "Randomize"

        InsertionSorting ->
            "Insertion Sort"

        SelectionSorting ->
            "Selectioin Sort"

        QuickSorting ->
            "Quick Sort"

        MergeSorting ->
            "Merge Sort"


nextMsg : PrevState -> Msg
nextMsg prevState =
    case prevState of
        None ->
            NoOp

        Insertion ->
            InsertionSort dummyPosix

        Selection ->
            SelectionSort dummyPosix

        Quick ->
            QuickSort dummyPosix

        Merge ->
            MergeSort dummyPosix



--MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



--MODEL


type State
    = Stop
    | Randomizing
    | InsertionSorting
    | SelectionSorting
    | QuickSorting
    | MergeSorting


type PrevState
    = None
    | Insertion
    | Selection
    | Quick
    | Merge


type alias Model =
    { barList : List Int
    , deltaX : Float
    , singleSlider : SingleSlider.SingleSlider Msg
    , state : State
    , prevState : PrevState
    , isStopped : Bool
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { barList = List.range 1 25
      , deltaX = 25
      , singleSlider =
            SingleSlider.init
                { min = 25
                , max = 100
                , value = 25
                , step = 1
                , onChange = SingleSliderChange
                }
                |> SingleSlider.withMinFormatter (always "")
                |> SingleSlider.withMaxFormatter (always "")
                |> SingleSlider.withValueFormatter
                    (\n _ ->
                        String.concat
                            [ "- List Size: "
                            , String.fromFloat n
                            ]
                    )
      , state = Stop
      , prevState = None
      , isStopped = False
      }
    , Cmd.none
    )


type Msg
    = NoOp
    | Randomize
    | RandomizedList (List Int)
    | InsertionSort Time.Posix
    | SelectionSort Time.Posix
    | QuickSort Time.Posix
    | MergeSort Time.Posix
    | SingleSliderChange Float



--UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( { model
                | state = Stop
                , isStopped = not model.isStopped
              }
            , Cmd.none
            )

        Randomize ->
            ( model
            , generate RandomizedList (shuffle model.barList)
            )

        RandomizedList randomizedList ->
            ( { model
                | state = Randomizing
                , prevState = None
                , barList = randomizedList
                , isStopped = False
              }
            , Cmd.none
            )

        InsertionSort _ ->
            ( { model
                | barList = insertionSort model.barList
                , state = InsertionSorting
                , prevState = Insertion
                , isStopped = False
              }
            , Cmd.none
            )

        SelectionSort _ ->
            ( { model
                | barList = selectionSort model.barList
                , state = SelectionSorting
                , prevState = Selection
                , isStopped = False
              }
            , Cmd.none
            )

        QuickSort _ ->
            ( { model
                | barList = quickSort model.barList
                , state = QuickSorting
                , prevState = Quick
                , isStopped = False
              }
            , Cmd.none
            )

        MergeSort _ ->
            ( { model
                | barList = mergeSort model.barList
                , state = MergeSorting
                , prevState = Merge
                , isStopped = False
              }
            , Cmd.none
            )

        SingleSliderChange flt ->
            let
                newSlider =
                    SingleSlider.update flt model.singleSlider

                newDeltaX =
                    if flt > 90 then
                        flt * 0.08

                    else if flt > 80 then
                        flt * 0.11

                    else if flt > 66 then
                        flt * 0.15

                    else if flt > 50 then
                        flt * 0.2

                    else if flt > 45 then
                        flt * 0.3

                    else if flt > 30 then
                        flt * 0.5

                    else
                        flt
            in
            ( { model
                | singleSlider = newSlider
                , barList = List.range 1 (round flt)
                , deltaX = newDeltaX
              }
            , Cmd.none
            )



--SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        InsertionSorting ->
            Time.every 400 InsertionSort

        SelectionSorting ->
            Time.every 400 SelectionSort

        QuickSorting ->
            Time.every 400 QuickSort

        MergeSorting ->
            Time.every 400 MergeSort

        Randomizing ->
            Sub.none

        Stop ->
            Sub.none



--VIEW


view : Model -> Html Msg
view model =
    div [ style "padding" "30px" ]
        [ header
            [ style "color" "#6e7372"
            , style "font-size" "30px"
            , style "font-weight" "800"
            ]
            [ text "Comparison Sorting Algorithms" ]
        , div [ style "padding-top" "35px" ] [ barChart (adjustedGraphAttributes model) (floatedList model.barList) ]
        , div []
            [ sortButton Randomize Randomizing
            , sortButton (InsertionSort dummyPosix) InsertionSorting
            , sortButton (SelectionSort dummyPosix) SelectionSorting
            , sortButton (QuickSort dummyPosix) QuickSorting
            , sortButton (MergeSort dummyPosix) MergeSorting
            , controllButton NoOp Stop model.prevState model.isStopped
            ]
        , div [ style "padding-top" "15px" ] [ SingleSlider.view model.singleSlider ]
        ]


sortButton : Msg -> State -> Html Msg
sortButton message state =
    baseButton message False (stateString state) "#333" "#fff"


controllButton : Msg -> State -> PrevState -> Bool -> Html Msg
controllButton message state prevState isStopped =
    let
        isDisabled =
            if prevState == None then
                True

            else
                False

        nextOp =
            if isStopped == True then
                nextMsg prevState

            else
                message

        title =
            if isStopped == True && state == Stop then
                "Restart"

            else
                stateString state
    in
    baseButton nextOp
        isDisabled
        title
        "#fff"
        "#f08080"


baseButton : Msg -> Bool -> String -> String -> String -> Html Msg
baseButton message isDisabled title color backgroundColor =
    button
        [ style "margin" "13px 5px"
        , style "font-size" "16px"
        , style "font-weight" "500"
        , style "border" "0.1em solid #6e7372"
        , style "padding" "0.5em 1em"
        , style "color" color
        , style "background-color" backgroundColor
        , onClick message
        , disabled isDisabled
        ]
        [ text title ]
