from qutebrowser.api import interceptor
from urllib.parse import urljoin
from PyQt5.QtCore import QUrl
import operator

o = operator.methodcaller
s = "setHost"
i = interceptor

# def farside(url: QUrl, r) -> bool:
#     url.setHost("farside.link")
#     p = url.path().strip("/")
#     url.setPath(urljoin(r, p))
#     return True

# redirects = [
#     "imgur.com",
#     "medium.com",
#     "tiktok.com",
#     "www.tiktok.com"
# ]

# def f(info: i.Request):
#     if info.resource_type != i.ResourceType.main_frame or info.request_url.scheme() in {
#         "data",
#         "blob",
#     }:
#         return

#     url = info.request_url
#     if url.host() in redirects:
#         info.redirect(farside(url, url.host()))

# i.register(f)

# <gemini://gemini.circumlunar.space/> -> <https://portal.mozz.us/gemini/gemini.circumlunar.space/>
def proxy_gemini(url: QUrl, r) -> bool:
    gemini_host = url.host()
    gemini_path = url.path()

    url.setScheme("https")
    url.setHost("portal.mozz.us")
    url.setPath("/gemini/" + gemini_host + urljoin(r, gemini_path))

def f(info: i.Request):
    if info.resource_type != i.ResourceType.main_frame or info.request_url.scheme() in {
        "data",
        "blob",
    }:
        return

    url = info.request_url
    if url.scheme() == "gemini": info.redirect(proxy_gemini(url, url.host()))

i.register(f)
