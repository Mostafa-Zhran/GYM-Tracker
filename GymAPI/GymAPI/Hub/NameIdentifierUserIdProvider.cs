using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

public class NameIdentifierUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
    {
        // ✅ Try all possible claim names after DefaultInboundClaimTypeMap.Clear()
        return connection.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? connection.User?.FindFirst("sub")?.Value
            ?? connection.User?.FindFirst("nameid")?.Value
            ?? connection.User?.FindFirst("uid")?.Value;
    }
}