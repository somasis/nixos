# Redirect certain sites to open-source proxies
# Derived from <https://github.com/Phantop/dotfiles/blob/d561366659c5aea1846f49d5186dd178058f7268/qutebrowser/redirects.py>
{
  programs.qutebrowser.extraConfig = ''
    from qutebrowser.api import interceptor
    from urllib.parse import urljoin
    from PyQt5.QtCore import QUrl
    import operator

    o = operator.methodcaller
    s = "setHost"
    i = interceptor


    def farside(url: QUrl, i) -> bool:
        url.setHost("farside.link")
        p = url.path().strip("/")
        url.setPath(urljoin(i, p))
        return True


    def imgur(url: QUrl) -> bool:
        return farside(url, "/rimgo/")


    def medium(url: QUrl) -> bool:
        return farside(url, "/scribe/")


    def instagram(url: QUrl) -> bool:
        return farside(url, "/bibliogram/")


    # def gtranslate(url: QUrl) -> bool:
    #     return farside(url, "/simplytranslate/")


    redirects = {
        "imgur.com": imgur,
        "instagram.com": instagram,
        "medium.com": medium,
        # "translate.google.com": gtranslate,
    }


    def f(info: i.Request):
        if info.resource_type != i.ResourceType.main_frame or info.request_url.scheme() in {
            "data",
            "blob",
        }:
            return

        url = info.request_url
        redir = redirects.get(url.host())

        if redir is not None and redir(url) is not False:
            info.redirect(url)


    i.register(f)
  '';
}
