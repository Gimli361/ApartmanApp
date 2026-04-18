using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/ariza/{arizaId:int}/foto")]
[Authorize]
public class FotoController(IFotoService fotoService) : ControllerBase
{
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
