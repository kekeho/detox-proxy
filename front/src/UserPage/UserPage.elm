module UserPage.UserPage exposing (..)

import Http
import Json.Encode as E
import UserPage.Model exposing (..)
import List



type BlockListInputType
    = Active Bool
    | Host String
    | Start String
    | End String


type UserPageMsg
    = GetLoginUserInfo
    | GotLoginUserInfo (Result Http.Error User)
    | BlockListInput BlockId BlockListInputType
    | NewBlockAddress
    | RegistNewBlocks
    | GotRegistNewBlockResult (Result Http.Error ())


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

        NewBlockAddress ->
            let
                tempId = (List.length model.blockPanel)
            in
            ( { model | blockPanel = model.blockPanel ++ [newBlockAddress tempId] }
            , Cmd.none
            )
        
        RegistNewBlocks ->
            let
                normalized =
                    List.map normalize model.blockPanel
                error =
                    List.filter
                        ( \x ->
                            case x of
                                Err _ ->
                                    True
                                
                                Ok _ ->
                                    False
                        )
                        normalized
            in
            case error of
                [] ->
                    let
                        success =
                            List.map Result.toMaybe normalized
                                |> List.filterMap (\x -> x)
                        new =
                            List.filter
                                (\x ->
                                    case x.id of
                                        New _ -> True
                                        Id _ -> False
                                )
                                success
                    in
                    ( model
                    , registNewBlockAddress new
                    )
                _ ->
                    let
                        blockPanel =
                                List.map2
                                    (\nb b ->
                                        case nb of
                                            Ok _ ->
                                                b
                                            Err e ->
                                                { b | error = e }
                                    )
                                    normalized
                                    model.blockPanel
                    in
                    ( { model | blockPanel = blockPanel }
                    , Cmd.none
                    )

        _ ->
            ( model
            , Cmd.none
            )
            



-- CMD

getLoginUserInfo : Cmd UserPageMsg
getLoginUserInfo =
    Http.get
        { url = "/api/user"
        , expect = Http.expectJson GotLoginUserInfo userDecoder
        }


registNewBlockAddress : List NormalizedBlockAddress -> Cmd UserPageMsg
registNewBlockAddress blockList =
    Http.post
        { url = "/api/user/blockaddress"
        , body = Http.jsonBody (E.list blockAddressEncoder blockList)
        , expect = Http.expectWhatever GotRegistNewBlockResult
        }
