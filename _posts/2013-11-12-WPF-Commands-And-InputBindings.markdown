---
layout: post
author: Owen Rumney
title: WPF Commands and Events with MVVM
tags: [wpf commands, input bindings, windows programming]
---

I have been doing some revision on my WPF, particularly around ModelView-View-Model pattern. One thing that I've always found a bit difficult to get right is the handling of events on the window and getting them back to the view model.

I personally believe that the goal of a completely empty code behind should be a best efforts approach rather than mandatory, sometime there is a need for purely UI related code and this, in my view is the correct place.

I wanted to trigger a command when a key was pressed in a TextBox on my Window, in the past I've used the PreviewKeyDown and had a handler in the code-behind which has invoked the command on the ViewModel; this has never seemed correct or particularly satisfying.
In my current play project I decided to find a better way to achieve this and I think I have - InputBindings.

On my ViewModel I have a DelegateCommand called AddTicker which I pass delegates for the Execute and CanExecute,

{% highlight csharp %}
public ICommand AddTicker {get; private set;}
{% endhighlight %}

to bind to this from a button is easy, and now the same can be said for a Key press using the following XAML;

{% highlight xml  %}
<TextBox.InputBindings>
<KeyBinding Key="Return" Command="{Binding AddTicker}"></KeyBinding>
</TextBox.InputBindings>
{% endhighlight %}

As an aside, it took me a while to remember how to get the CanExecuteChanged to fire without some ugly callback mechanism, I knew it involved a registration and it eventually came to me;

{% highlight csharp table %}
CommandManager.RequerySuggested += (s, e) => RaiseCanExecuteChanged();

public void RaiseCanExecuteChanged()
{
if (CanExecuteChanged != null)
{
CanExecuteChanged(this, EventArgs.Empty);
}
}
{% endhighlight %}
