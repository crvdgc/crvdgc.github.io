--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import qualified GHC.IO.Encoding as E
import Hakyll

import Debug.Trace (traceShowId)

--------------------------------------------------------------------------------
main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  hakyllWith config $ do
    match ("images/*"
            .||. "assets/*"
            .||. "css/*"
            .||. "css/font/*"
            .||. "google85266e65053758c9.html"
            .||. "favicon.ico"
          ) $ do
      route idRoute
      compile copyFileCompiler

    -- posts
    match "portfolio/*" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler
          >>= loadAndApplyTemplate "templates/post.html" postCtx
          >>= saveSnapshot "content"
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

    -- meta
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "portfolio/*"
        let ctx = indexCtx posts
        getResourceBody
          >>= applyAsTemplate ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls
    match "about.md" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler
          >>= loadAndApplyTemplate "templates/default.html" siteCtx
          >>= relativizeUrls
    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "portfolio/*"
        let ctx = archiveCtx posts
        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls
    create ["404.html"] $ do
      route idRoute
      compile $ do
        makeItem ""
          >>= loadAndApplyTemplate "templates/404.html" notFoundCtx
          >>= loadAndApplyTemplate "templates/default.html" notFoundCtx
          >>= relativizeUrls
    match "templates/*" $ compile templateCompiler

    -- feed
    create ["atom.xml"] $ do
        route idRoute
        compile (feedCompiler renderAtom)
    create ["rss.xml"] $ do
        route idRoute
        compile (feedCompiler renderRss)

--------------------------------------------------------------------------------
siteCtx :: Context String
siteCtx = activeClassField <> defaultContext

postCtx :: Context String
postCtx = dateField "date" "%Y-%m-%d" <> siteCtx

feedCtx :: Context String
feedCtx = bodyField "description" <> postCtx

listWithTitleCtx :: String -> [Item String] -> Context String
listWithTitleCtx title posts =
  listField "posts" postCtx (pure posts)
    <> constField "title" title
    <> siteCtx

indexCtx :: [Item String] -> Context String
indexCtx = listWithTitleCtx "Home"

archiveCtx :: [Item String] -> Context String
archiveCtx = listWithTitleCtx "Archives"

notFoundCtx :: Context String
notFoundCtx = constField "title" "Not Found" <> postCtx

-- https://groups.google.com/forum/#!searchin/hakyll/if$20class/hakyll/WGDYRa3Xg-w/nMJZ4KT8OZUJ
activeClassField :: Context a
activeClassField =
  functionField "activeClass" $ \[p] _ -> do
    path <- toFilePath <$> getUnderlying
    return $
      if path == p
        then "active"
        else path

-- change output folder to docs for Github pages
config :: Configuration
config = defaultConfiguration {destinationDirectory = "docs"}

-- * Feeds
-- https://jaspervdj.be/hakyll/tutorials/05-snapshots-feeds.html
-- and
-- https://robertwpearce.com/hakyll-pt-3-generating-rss-and-atom-xml-feeds.html

feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration
  { feedTitle = "Crvdgc 的个人文集"
  , feedDescription = "不定期发布自己创作的小说，以及一些关于哲学、计算机科学、小说、电影和游戏的思考。"
  , feedAuthorName = "crvdgc"
  , feedAuthorEmail = "ubikium@gmail.com"
  , feedRoot = "https://crvdgc.github.io"
  }

type FeedRenderer =
  FeedConfiguration
  -> Context String
  -> [Item String]
  -> Compiler (Item String)

feedCompiler :: FeedRenderer -> Compiler (Item String)
feedCompiler renderer =
  renderer feedConfig feedCtx
    =<< fmap (take 10) . recentFirst
    =<< loadAllSnapshots "portfolio/*" "content"
