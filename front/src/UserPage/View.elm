-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module UserPage.View exposing (..)

import UserPage.Model exposing (..)
import UserPage.UserPage exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view : UserPageModel -> (String, List (Html UserPageMsg))
view model =
    ( "userpage"
    , [ blockListPanelView model
      ]
    )


blockListPanelView : UserPageModel -> Html UserPageMsg
blockListPanelView model =
    div [ class "blocklist panel" ]
        [ h1 [] [ text "ブロックリスト" ]
        , div [ ]
            [ blockListView model 
            , controlView model
            ]
        ]


blockListView : UserPageModel -> Html UserPageMsg
blockListView model =
    div [ class "blocklist-container" ]
        [ table [ class "block-list" ]
            [ col [ class "active" ] []
            , col [ class "host" ] []
            , col [ class "start" ] []
            , col [ class "end" ] []
            , col [ class "delete" ] []
            , thead []
                [ tr [] 
                    [ th [] [ text "ON" ]
                    , th [] [ text "Host" ]
                    , th [] [ text "遮断 [分]" ]
                    , th [] [ text "再開 [分]" ]
                    , th [] [ text "削除" ]
                    ]
                ]
            ]
        , model.blockPanel
            |> notDelBlockFilter
            |> List.map blockRowView
            |> div [ class "body" ]
        ]


blockRowView : BlockAddress -> Html UserPageMsg
blockRowView block =
    div [ class "block-row" ]
        [ table [ ]
            [ col [ class "active" ] []
            , col [ class "host" ] []
            , col [ class "start" ] []
            , col [ class "end" ] []
            , col [ class "delete" ] []
            , button 
                [ onClick (BlockListInput block.id <| Active <| not block.active) 
                , class <| if block.active then "active" else ""
                , class "on-off"
                ]
                []
            , td (class "host bold" :: if isContain Url block.error then [ class "error" ] else [])
                [ input
                    [ type_ "url", value block.url
                    , onInput (\s -> BlockListInput block.id <| Host s)
                    ]
                    []
                ]
            , td (class "start" :: if isContain UserPage.Model.Start block.error then [ class "error" ] else [])
                [ input
                    [ type_ "number", value <| block.start
                    , onInput (\s -> BlockListInput block.id <| UserPage.UserPage.Start s)
                    ]
                    []
                ]
            , td (class "end" :: if isContain UserPage.Model.End block.error then [ class "error" ] else [])
                [ input
                    [ type_ "number", value <| block.end
                    , onInput (\s -> BlockListInput block.id <| UserPage.UserPage.End s)
                    ]
                    []
                ]
            ,  button 
                [ onClick (BlockListInput block.id <| UserPage.UserPage.Delete)
                , class "delete"
                ]
                []
            ]
        ]


controlView : UserPageModel -> Html UserPageMsg
controlView model =
    div [ class "control" ]
        [ button
            [ class "add-block", onClick NewBlockAddress ]
            [ text "追加" ]
        , button
            [ class "update", onClick RegistAndUpdateBlocks ]
            [ text "更新" ]
        ]


-- Func

isContain : a -> List a -> Bool
isContain a list =
    List.filter (\x -> x == a) list
        |> List.length
        |> (\i -> i > 0)
