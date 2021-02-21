module UserPage.Model exposing (..)

import Json.Decode as D
import Json.Encode as E
import Http


type alias UserPageModel =
    { user : Maybe (Result Http.Error User)
    , blockPanel : List BlockAddress
    }


type alias User =
    { id: Int
    , username: String
    , email: String
    , block: List BlockAddress
    }


type BlockId
    = Id Int
    | New Int


type ErrorCol
    = Url
    | Start
    | End


type alias BlockAddress =
    { id : BlockId
    , url : String
    , start : String
    , end : String
    , active : Bool
    , error : List ErrorCol
    }


type alias NormalizedBlockAddress =
    { id : BlockId
    , url : String
    , start : Int
    , end : Int
    , active : Bool
    }


-- INIT

initUserPageModel : UserPageModel
initUserPageModel =
    UserPageModel
        Nothing
        []


newBlockAddress : Int -> BlockAddress
newBlockAddress tempId =
    BlockAddress (New tempId) "" "5" "10" True []


-- Func

normalize : BlockAddress -> Result (List ErrorCol) NormalizedBlockAddress
normalize b =
    let
        (start, end, url) =
            ( String.toInt b.start
            , String.toInt b.end
            , normalizeUrl b.url
            )    
    in
    case (start, end, url) of
        (Just s, Just e, Just u) ->
            Ok <|
                NormalizedBlockAddress b.id u s e b.active
        _ ->
            [ (Start, start)
            , (End, end)
            ]
                |> List.filter (\(_, a) -> a == Nothing)
                |> List.map (\(a, _) -> a)
                |> (++) (if url == Nothing then [ Url ] else [])
                |> Err


normalizeUrl : String -> Maybe String
normalizeUrl rawurl =
    if String.contains "\n" rawurl then
        Nothing
    else if String.contains "/" rawurl then
        Nothing
    else if not <| String.contains "." rawurl then
        Nothing
    else
        Just rawurl


-- Decoder

userDecoder : D.Decoder User
userDecoder =
    D.map4 User
        (D.field "id" D.int)
        (D.field "username" D.string)
        (D.field "email" D.string)
        (D.field "blocklist" (D.list blockAddressDecoder))


blockAddressDecoder : D.Decoder BlockAddress
blockAddressDecoder =
    D.map6 BlockAddress
        (D.field "id" (D.map (Id) D.int))
        (D.field "url" D.string)
        (D.field "start" (D.map String.fromInt D.int))
        (D.field "end" (D.map String.fromInt D.int))
        (D.field "active" D.bool)
        (D.succeed [])


-- Encoder

blockAddressEncoder : NormalizedBlockAddress -> E.Value
blockAddressEncoder b =
    E.object
        [ ("url", E.string b.url)
        , ("start", E.int b.start)
        , ("end", E.int b.end)
        , ("active", E.bool b.active)
        ]
