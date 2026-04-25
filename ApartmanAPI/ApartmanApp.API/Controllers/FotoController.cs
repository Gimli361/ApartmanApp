using System.Security.Claims;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/ariza/{arizaId:int}/foto")]
[Authorize]
public class FotoController(IFotoService fotoService, IArizaService arizaService) : ControllerBase
{
    private bool TryGetCurrentUserId(out int id) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out id) && id > 0;

    [HttpGet]
    public async Task<IActionResult> GetAll(int arizaId)
    {
        var result = await fotoService.GetByArizaIdAsync(arizaId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Upload(int arizaId, IFormFile dosya)
    {
        if (!TryGetCurrentUserId(out var currentUserId))
            return Unauthorized();

        // Sadece arızayı bildiren kullanıcı veya admin foto yükleyebilir
        if (!User.IsInRole("Admin"))
        {
            var arizaResult = await arizaService.GetByIdAsync(arizaId);
            if (!arizaResult.Success)
                return NotFound(arizaResult);
            if (arizaResult.Data!.BildirenId != currentUserId)
                return Forbid();
        }

        var result = await fotoService.UploadAsync(arizaId, dosya);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    [HttpDelete("{fotoId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int arizaId, int fotoId)
    {
        var result = await fotoService.DeleteAsync(fotoId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}
