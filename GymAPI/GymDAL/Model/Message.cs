using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Model
{
    public class Message
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public string SenderId { get; set; }
        public ApplicationUser Sender { get; set; }

        public string ReceiverId { get; set; }
        public ApplicationUser Receiver { get; set; }

        public string Content { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        public bool IsSeen { get; set; } = false;
    }
}
