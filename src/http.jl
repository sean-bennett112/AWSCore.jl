#==============================================================================#
# http.jl
#
# HTTP Requests with retry/back-off and HTTPException.
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

import Base: show, UVError


http_status(e::HTTP.StatusError) = e.status
header(e::HTTP.StatusError, k, d="") = HTTP.header(e.response, k, d)
http_message(e::HTTP.StatusError) = String(e.response.body)
content_type(e::HTTP.StatusError) = HTTP.header(e.response, "Content-Type")


function http_request(request::AWSRequest)

    @repeat 4 try

        options = []
        if get(request, :return_stream, false)
            io = BufferStream()
            request[:response_stream] = io
            push!(options, (:response_stream, io))
        end

        return HTTP.request(request[:verb],
                            request[:url],
                            request[:headers],
                            request[:content];
                            options...)

    catch e

        @delay_retry if isa(e, Base.DNSError) ||
                        isa(e, HTTP.ParsingError) ||
                        isa(e, HTTP.IOError) ||
                        (isa(e, HTTP.StatusError) && http_status(e) >= 500) end
    end

    assert(false) # Unreachable.
end


function http_get(url::String)

    host = HTTP.URIs.hostname(HTTP.URI(url))

    http_request(@SymDict(verb = "GET",
                          url = url,
                          headers = Dict("Host" => host),
                          content = UInt8[]))
end



#==============================================================================#
# End of file.
#==============================================================================#
