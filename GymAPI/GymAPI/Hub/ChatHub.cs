using GymBLL.DTO;
using GymDAL.DB;
using GymDAL.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

[Authorize]
public class ChatHub : Hub
{
    private readonly AppDbContext _context;

    public ChatHub(AppDbContext context)
    {
        _context = context;
    }
    public async Task Ping()
    {
        Console.WriteLine("PING RECEIVED");
        await Clients.Caller.SendAsync("Pong");
    }
    public async Task SendMessage(string receiverId, string content)
    {
        try
        {
            // ✅ Try all possible claim names
            var senderId =
                Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? Context.User?.FindFirst("sub")?.Value
                ?? Context.User?.FindFirst("nameid")?.Value
                ?? Context.User?.FindFirst("uid")?.Value;

            Console.WriteLine($"SenderId: {senderId}");
            Console.WriteLine($"ReceiverId: {receiverId}");
            Console.WriteLine($"Content: {content}");

            // Print ALL claims so we can see exactly what's in the token
            if (Context.User != null)
            {
                foreach (var claim in Context.User.Claims)
                {
                    Console.WriteLine($"CLAIM → {claim.Type} = {claim.Value}");
                }
            }

            if (string.IsNullOrEmpty(senderId))
                throw new HubException("senderId is null — check JWT claims.");

            var msg = new Message
            {
                Id = Guid.NewGuid(),
                SenderId = senderId,
                ReceiverId = receiverId,
                Content = content,
                Timestamp = DateTime.UtcNow,
                IsSeen = false
            };

            _context.Messages.Add(msg);
            await _context.SaveChangesAsync();

            var dto = new ChatMessageDto
            {
                Id = msg.Id,
                SenderId = msg.SenderId,
                ReceiverId = msg.ReceiverId,
                Content = msg.Content,
                Timestamp = msg.Timestamp,
                IsSeen = false
            };

            await Clients.User(receiverId).SendAsync("ReceiveMessage", dto);
            await Clients.Caller.SendAsync("MessageSent", dto);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR IN SENDMESSAGE: {ex}");
            throw;
        }
    }
    public async Task Typing(string receiverId)
    {
        var senderId = Context.UserIdentifier;

        await Clients.User(receiverId)
            .SendAsync("UserTyping", senderId);
    }
}