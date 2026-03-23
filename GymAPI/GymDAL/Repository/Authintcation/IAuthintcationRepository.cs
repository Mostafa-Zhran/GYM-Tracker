using GymDAL.Model;
using GymDAL.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Repository.Authintcation
{
    public interface IAuthenticationRepository
    {
        Task<(bool IsSuccess, string? Error)> User_RegisterAsync(ApplicationUser user, string Password);
        Task<(bool IsSuccess, string? Error)> CreateSocialUserAsync(ApplicationUser user);
        Task<(bool IsSuccess, string? Error)> CheckPassword(ApplicationUser user, string Password);

        Task<ApplicationUser> GetUserByEmailAsync(string Email);

    }
}
