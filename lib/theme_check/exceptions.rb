# frozen_string_literal: true
require "net/http"

module ThemeCheck
  TIMEOUT_EXCEPTIONS = [
    Net::ReadTimeout,
    Net::OpenTimeout,
    Net::WriteTimeout,
    Errno::ETIMEDOUT,
    Timeout::Error,
  ]

  CONNECTION_EXCEPTIONS = [
    IOError,
    EOFError,
    SocketError,
    Errno::EINVAL,
    Errno::ECONNRESET,
    Errno::ECONNABORTED,
    Errno::EPIPE,
    Errno::ECONNREFUSED,
    Errno::EAGAIN,
    Errno::EHOSTUNREACH,
    Errno::ENETUNREACH,
  ]

  NET_HTTP_EXCEPTIONS = [
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    *TIMEOUT_EXCEPTIONS,
    *CONNECTION_EXCEPTIONS,
  ]
end
