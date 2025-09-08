@ComponentV2
export struct SrtTest {

  private testSrtString: string = "1\n" +
    "\n" +
    "00:07:06,517 --> 00:07:11,229\n" +
    "\n" +
    "<ruby>text A<rp> (</rp><rt>annotation A</rt><rp>) </rp>unannotated text B<rt></rt>text C<rp> (</rp><rt>annotation C</rt><rp>) </rp>text D<rp> (</rp><rt>annotation D</rt><rp>) </rp></ruby>\n" +
    "\n" +
    " \n" +
    "\n" +
    "2\n" +
    "\n" +
    "00:07:11,964 --> 00:07:13,909\n" +
    "\n" +
    "<ruby>text E<rp> (</rp><rt>annotation E</rt><rp>) </rp>text F<rp> (</rp><rt>annotation F</rt><rp>) </rp> unannotated text G<rt></rt></ruby>"

  build() {

  }

}