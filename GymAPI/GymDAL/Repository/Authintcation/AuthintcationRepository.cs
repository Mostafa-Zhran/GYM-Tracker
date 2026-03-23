using GymDAL.DB;
using GymDAL.Model;
using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Repository.Authintcation
{
    public class AuthenticationRepository : IAuthenticationRepository
    {
        private readonly AppDbContext _AppContext;
        private readonly UserManager<ApplicationUser> _UserManager;

        public AuthenticationRepository(AppDbContext appContext, UserManager<ApplicationUser> userManager)
        {
            _AppContext = appContext;
            _UserManager = userManager;
        }

        public async Task<(bool IsSuccess, string? Error)> CheckPassword(ApplicationUser user, string Passwors)
        {
            bool validPassword = await _UserManager.CheckPasswordAsync(user, Passwors);
            if (!validPassword)
            {
                var errors = string.Join("; ", "Invalid Email or Password");
                return (false, errors);
            }
            return (true, null);
        }

        public async Task<ApplicationUser> GetUserByEmailAsync(string email)
        {
            var user = await _UserManager.FindByEmailAsync(email);
            return user;
        }

        public async Task<(bool IsSuccess, string? Error)> User_RegisterAsync(ApplicationUser user, string Password)
        {
            var result = await _UserManager.CreateAsync(user, Password);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return (false, errors);
            }
            return (true, null);
        }

        public async Task<(bool IsSuccess, string? Error)> DeleteUser(ApplicationUser user)
        {
            var result = await _UserManager.DeleteAsync(user);

            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return (false, errors);
            }
            return (true, null);

        }

        public async Task<(bool IsSuccess, string? Error)> CreateSocialUserAsync(ApplicationUser user)
        {
           var result = await _UserManager.CreateAsync(user);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return (false, errors);
            }
            return (true, null);
        }
    }
}
