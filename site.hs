--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import qualified GHC.IO.Encoding as E
import Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = do
  E.setLocaleEncoding E.utf8
  hakyllWith config $ do
    match "images/*" $ do
      route idRoute
      compile copyFileCompiler
    match "assets/*" $ do
      route idRoute
      compile copyFileCompiler
    match "css/*" $ do
      route idRoute
      compile compressCssCompiler
    match "css/font/*" $ do
      route idRoute
      compile copyFileCompiler
    match (fromList ["about.md"]) $ do
      route $ setExtension "html"
      compile $
        pandocCompiler >>= loadAndApplyTemplate "templates/default.html" siteCtx
          >>= relativizeUrls
    match "portfolio/*" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler >>= loadAndApplyTemplate "templates/post.html" postCtx
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls
    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "portfolio/*"
        let archiveCtx =
              listField "posts" postCtx (return posts)
                `mappend` constField "title" "Archives"
                `mappend` siteCtx
        makeItem "" >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" archiveCtx
          >>= relativizeUrls
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "portfolio/*"
        let indexCtx =
              listField "posts" postCtx (return posts)
                `mappend` constField "title" "Home"
                `mappend` siteCtx
        getResourceBody >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls
    match "google85266e65053758c9.html" $ do
      route idRoute
      compile copyFileCompiler
    match "favicon.ico" $ do
      route idRoute
      compile copyFileCompiler
    match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx = dateField "date" "%B %e, %Y" `mappend` siteCtx

siteCtx :: Context String
siteCtx = activeClassField `mappend` defaultContext

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
