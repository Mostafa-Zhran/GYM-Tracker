using GymBLL.Exceptions;
using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Text.Json;
namespace Sina_API.MiddleWare
{

    /// <summary>
    /// Global exception handling middleware that catches all unhandled exceptions
    /// and returns a consistent response format matching Response<T> wrapper.
    /// 
    /// This follows Clean Architecture by:
    /// - Separating cross-cutting concerns (exception handling) from business logic
    /// - Providing consistent error responses to the frontend
    /// - Allowing Managers to throw business exceptions without knowing HTTP details
    /// </summary>
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, ex.Message);
                await HandleException(context, ex);
            }
        }

        private Task HandleException(HttpContext context, Exception ex)
        {
            HttpStatusCode statusCode;
            string message = ex.Message;

            // Map exception types to HTTP status codes
            switch (ex)
            {
 
                case BadRequestException:
                    statusCode = System.Net.HttpStatusCode.BadRequest;
                    break;

                case NotFoundException:
                    statusCode = HttpStatusCode.NotFound;
                    break;

                case UnauthorizedException:
                    statusCode = HttpStatusCode.Unauthorized;
                    break;

                case ForbiddenException:
                    statusCode = HttpStatusCode.Forbidden;
                    break;

                case InvalidOperationException:
                    // Business logic errors (e.g., email already exists)
                    statusCode = HttpStatusCode.BadRequest;
                    break;

                default:
                    statusCode = System.Net.HttpStatusCode.InternalServerError;
                    message = "An unexpected error occurred";
                    break;
            }

            // Return response in the SAME format as Response<T> wrapper
            // Properties: Message, Data, IsSucceded, DateTime
            var response = new
            {
                Message = message,
                Data = (object?)null,
                IsSucceded = false,
                DateTime = DateTime.Now
            };

            context.Response.StatusCode = (int)statusCode;
            context.Response.ContentType = "application/json";

            var jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };

            return context.Response.WriteAsync(JsonSerializer.Serialize(response, jsonOptions));
        }
    }

}
