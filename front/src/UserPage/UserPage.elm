-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

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
    | Delete


type UserPageMsg
    = BlockListInput BlockId BlockListInputType
    | NewBlockAddress
    | RegistAndUpdateBlocks
    | GotRegistNewBlockResult (Result Http.Error ())
    | GotDeleteBlockResult (Result Http.Error ())
    | GotBlockAddressList (Result Http.Error (List BlockAddress))


update : UserPageMsg -> UserPageModel -> (UserPageModel, Cmd UserPageMsg)
update msg model =
    case msg of
        BlockListInput blockId inputType ->
            case inputType of
                Active bool ->
                    let
                        blockList =
                            model.blockPanel
                                |> List.map
                                    (\b -> 
                                        if b.id == blockId
                                            then { b | id = updateOrNew b.id, active = bool } 
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
                                            then { b | id = updateOrNew b.id, url = host } 
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
                                            then { b | id = updateOrNew b.id, start = startMin } 
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
                                            then { b | id = updateOrNew b.id, end = endMin } 
                                            else b
                                    )
                    in
                    ( { model | blockPanel = blockList }
                    , Cmd.none
                    )
                
                Delete ->
                    let
                        blockList =
                            model.blockPanel
                                |> List.map
                                    (\b ->
                                        if b.id == blockId
                                            then { b | id = UserPage.Model.Delete <| blockIdVal b.id }
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
        
        RegistAndUpdateBlocks ->
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
                    in
                    ( model
                    , Cmd.batch
                        [ registNewBlockAddress <| newBlockAddressList success
                        , updateBlockAddress <| updateBlockAddressList success
                        , model.blockPanel
                            |> delBlockFilter
                            |> List.map (\b -> blockIdVal b.id)
                            |> deleteBlockAddress
                        ]
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

        GotRegistNewBlockResult result ->
            -- TODO: エラー処理
            ( model
            , getBlockAddressList  -- update
            )


        GotDeleteBlockResult result ->
            -- TODO: エラー処理
            ( model
            , getBlockAddressList  -- update
            )
        
        GotBlockAddressList result ->
            case result of
                Ok blockList ->
                    ( { model | blockList = Just result, blockPanel = blockList }
                    , Cmd.none
                    )
                Err _ ->
                    ( { model | blockList = Just result, blockPanel = [] }
                    , Cmd.none
                    )


-- CMD

getBlockAddressList : Cmd UserPageMsg
getBlockAddressList =
    Http.get
        { url = "/api/blockaddress"
        , expect = Http.expectJson GotBlockAddressList blockAddressListDecoder
        }


registNewBlockAddress : List NormalizedBlockAddress -> Cmd UserPageMsg
registNewBlockAddress blockList =
    Http.post
        { url = "/api/blockaddress"
        , body = Http.jsonBody (E.list blockAddressEncoder blockList)
        , expect = Http.expectWhatever GotRegistNewBlockResult
        }


updateBlockAddress : List NormalizedBlockAddress -> Cmd UserPageMsg
updateBlockAddress blockList =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "/api/blockaddress"
        , body = Http.jsonBody (E.list updateBlockAddressEncoder blockList)
        , expect = Http.expectWhatever GotRegistNewBlockResult
        , timeout = Nothing
        , tracker = Nothing
        }


deleteBlockAddress : List Int -> Cmd UserPageMsg
deleteBlockAddress blockList =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/api/blockaddress"
        , body = Http.jsonBody (E.list E.int blockList)
        , expect = Http.expectWhatever GotDeleteBlockResult
        , timeout = Nothing
        , tracker = Nothing
        }
