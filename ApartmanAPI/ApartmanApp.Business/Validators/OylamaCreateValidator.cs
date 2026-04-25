using ApartmanApp.Business.DTOs.Oylama;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class OylamaCreateValidator : AbstractValidator<OylamaCreateDto>
{
    public OylamaCreateValidator()
    {
        RuleFor(x => x.Baslik)
            .NotEmpty().WithMessage("Başlık boş olamaz.")
            .MaximumLength(150).WithMessage("Başlık en fazla 150 karakter olabilir.");

        RuleFor(x => x.Aciklama)
            .MaximumLength(1000)
            .When(x => !string.IsNullOrEmpty(x.Aciklama));

        RuleFor(x => x.BitisTarihi)
            .GreaterThan(DateTime.UtcNow).WithMessage("Bitiş tarihi gelecekte olmalıdır.");

        RuleFor(x => x.Secenekler)
            .NotNull().WithMessage("Seçenek listesi boş olamaz.")
            .Must(s => s != null && s.Count >= 2).WithMessage("En az 2 seçenek girilmelidir.")
            .Must(s => s != null && s.Count <= 10).WithMessage("En fazla 10 seçenek girilebilir.");

        RuleForEach(x => x.Secenekler)
            .NotEmpty().WithMessage("Seçenek metni boş olamaz.")
            .MaximumLength(100).WithMessage("Seçenek metni en fazla 100 karakter olabilir.");
    }
}
