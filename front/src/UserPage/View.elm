module UserPage.View exposing (..)

import UserPage.UserPage exposing (UserPageMsg)
import UserPage.Model exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view : User -> UserPageModel -> (String, List (Html UserPageMsg))
view user model =
    ( "userpage"
    , [ blockListPanelView user model
      ]
    )


blockListPanelView : User -> UserPageModel -> Html UserPageMsg
blockListPanelView user model =
    div [ class "blocklist panel" ]
        [ h1 [] [ text "ブロックリスト" ]
        , blockListView user model
        ]


blockListView : User -> UserPageModel -> Html UserPageMsg
blockListView user model =
    div [ class "block-list" ]
        (List.map blockRowView user.block)


blockRowView : BlockAddress -> Html UserPageMsg
blockRowView block =
    div [ class "block-row" ]
        [ text block.url ]
