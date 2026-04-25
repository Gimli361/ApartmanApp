using ApartmanApp.Business.DTOs.Auth;
using ApartmanApp.Core.Common;

namespace ApartmanApp.Business.Services.Abstract;

public interface IAuthService
{
    Task<Result<TokenResponseDto>> LoginAsync(LoginDto dto);
    Task<Result<TokenResponseDto>> RefreshAsync(string refreshToken);
    Task<Result> LogoutAsync(string refreshToken);
}
