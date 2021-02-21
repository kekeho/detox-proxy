module UserPage.UserPage exposing (..)

import Http
import UserPage.Model exposing (..)



type BlockListInputType
    = Active Bool
    | Host String
    | Start String
    | End String


type UserPageMsg
    = GetLoginUserInfo
    | GotLoginUserInfo (Result Http.Error User)
    | BlockListInput Int BlockListInputType



update : UserPageMsg -> UserPageModel -> (UserPageModel, Cmd UserPageMsg)
update msg model =
    case msg of
        GetLoginUserInfo ->
            ( model, getLoginUserInfo )
        
        GotLoginUserInfo result ->
            let
                blockPanel = 
                    case result of
                        Ok u ->
                            u.block
                        Err _ ->
                            []
            in
            ( { model | user = Just result, blockPanel = blockPanel }
            , Cmd.none
            )
        
        BlockListInput blockId inputType ->
            case inputType of
                Active bool ->
                    let
                        blockList =
                            model.blockPanel
                                |> List.map
                                    (\b -> 
                                        if b.id == blockId 
                                            then { b | active = bool } 
                                            else b
                                    )
                    in
                    ( { model | blockPanel = blockList }
                    , Cmd.none
                    )
                    
                Host host ->
                    let
                        blockList =
                            model.blockPanel
                                |> List.map
                                    (\b -> 
                                        if b.id == blockId 
                                            then { b | url = host } 
                                            else b
                                    )
                    in
                    ( { model | blockPanel = blockList }
                    , Cmd.none
                    )

                Start startMin ->
                    let
                        blockList =
                            model.blockPanel
                                |> List.map
                                    (\b -> 
                                        if b.id == blockId 
                                            then { b | start = startMin } 
                                            else b
                                    )
                    in
                    ( { model | blockPanel = blockList }
                    , Cmd.none
                    )

                End endMin ->
                    let
                        blockList =
                            model.blockPanel
                                |> List.map
                                    (\b -> 
                                        if b.id == blockId 
                                            then { b | end = endMin } 
                                            else b
                                    )
                    in
                    ( { model | blockPanel = blockList }
                    , Cmd.none
                    )



-- CMD

getLoginUserInfo : Cmd UserPageMsg
getLoginUserInfo =
    Http.get
        { url = "/api/user"
        , expect = Http.expectJson GotLoginUserInfo userDecoder
        }
